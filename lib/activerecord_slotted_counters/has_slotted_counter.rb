# frozen_string_literal: true

require "active_support"
require "activerecord_slotted_counters/utils"

require "activerecord_slotted_counters/adapters/rails_upsert"
require "activerecord_slotted_counters/adapters/pg_upsert"
require "activerecord_slotted_counters/adapters/sqlite_upsert"
require "activerecord_slotted_counters/adapters/mysql_upsert"

module ActiveRecordSlottedCounters
  class SlottedCounter < ::ActiveRecord::Base
    class NotSupportedAdapter < StandardError
      def initialize(adapter)
        @adapter = adapter
      end

      def message
        "The adapter not implemented yet (Rails #{ActiveRecord::VERSION::MAJOR}, #{@adapter})"
      end
    end

    scope :associated_records, ->(counter_name, klass) do
      where(counter_name: counter_name, associated_record_type: klass)
    end

    class << self
      def bulk_insert(attributes)
        on_duplicate_clause =
          "count = slotted_counters.count + #{slotted_counter_db_adapter.wrap_column_name("count")}"

        slotted_counter_db_adapter.bulk_insert(
          attributes,
          on_duplicate: Arel.sql(on_duplicate_clause),
          unique_by: :index_slotted_counters
        )
      end

      private

      def slotted_counter_db_adapter
        @slotted_counter_association_name ||= set_slotted_counter_db_adapter
      end

      def set_slotted_counter_db_adapter
        available_adapters = [
          ActiveRecordSlottedCounters::Adapters::MysqlUpsert,
          ActiveRecordSlottedCounters::Adapters::SqliteUpsert,
          ActiveRecordSlottedCounters::Adapters::PgUpsert,
          ActiveRecordSlottedCounters::Adapters::RailsUpsert
        ]

        current_adapter_name = connection.adapter_name

        adapter = available_adapters
          .map { |adapter| adapter.new(self) }
          .detect { |adapter| adapter.apply?(current_adapter_name) }

        raise NotSupportedAdapter.new(current_adapter_name) if adapter.nil?

        adapter
      end
    end
  end

  module BelongsToAssociation
    def update_counters_via_scope(klass, foreign_key, by)
      counter_name = reflection.counter_cache_column
      return super unless klass.registered_slotted_counter? counter_name

      klass.update_counters(foreign_key, counter_name => by, :touch => reflection.options[:touch])
    end
  end

  module HasSlottedCounter
    extend ActiveSupport::Concern
    include ActiveRecordSlottedCounters::Utils

    # TODO setup in gem config
    DEFAULT_MAX_SLOT_NUMBER = 100

    SLOTTED_COUNTERS_ASSOCIATION_OPTIONS = {
      class_name: "ActiveRecordSlottedCounters::SlottedCounter",
      foreign_key: "associated_record_id"
    }

    class_methods do
      include ActiveRecordSlottedCounters::Utils

      def has_slotted_counter(counter_type)
        counter_name = slotted_counter_name(counter_type)
        association_name = slotted_counter_association_name(counter_type)

        has_many association_name, ->(model) { associated_records(counter_name, model.class.to_s) }, **SLOTTED_COUNTERS_ASSOCIATION_OPTIONS

        scope :with_slotted_counters, ->(counter_type) do
          scope_association_name = slotted_counter_association_name(counter_type)
          return preload(scope_association_name) if ActiveRecord::VERSION::MAJOR >= 7

          scope_counter_name = slotted_counter_name(counter_type)
          counters = ActiveRecordSlottedCounters::SlottedCounter
            .where(
              counter_name: scope_counter_name,
              associated_record_id: self,
              associated_record_type: klass.to_s
            )

          grouped_counters = counters.group_by(&:associated_record_id)

          each do |record|
            assoc = record.association(scope_association_name)
            assoc.target = grouped_counters[record.id] || []
            assoc.loaded!
          end

          define_singleton_method(:find_each, method(:each))

          self
        end

        _slotted_counters << counter_type

        define_method(counter_name) do
          read_slotted_counter(counter_type)
        end
      end

      def update_counters(id, counters)
        touch = counters.delete(:touch)

        updated_counters_count = 0
        registered_counters, unregistered_counters = counters.partition { |name, _| registered_slotted_counter? name }.map(&:to_h)

        if unregistered_counters.present?
          unregistered_counters[:touch] = touch
          updated_unregistered_counters_count = super(id, unregistered_counters)
          updated_counters_count += updated_unregistered_counters_count
        end

        if registered_counters.present?
          ids = Array(id)
          updated_registered_counters_count = update_slotted_counters(ids, registered_counters, touch)
          updated_counters_count += updated_registered_counters_count
        end

        updated_counters_count
      end

      def reset_counters(id, *counters, touch: nil)
        registered_counters, unregistered_counters = counters.partition { |name| registered_slotted_counter? slotted_counter_name(name) }

        if unregistered_counters.present?
          super(id, *unregistered_counters, touch: touch)
        end

        if registered_counters.present?
          reset_slotted_counters(id, *registered_counters, touch: touch)
        end

        true
      end

      def slotted_counters
        if superclass.respond_to?(:slotted_counters)
          superclass.slotted_counters + _slotted_counters
        else
          _slotted_counters
        end
      end

      def registered_slotted_counter?(counter_name)
        counter_type = slotted_counter_type(counter_name)

        slotted_counters.include? counter_type
      end

      def update_slotted_counters(ids, registered_counters, touch)
        updated_counters_count = 0
        ActiveRecord::Base.transaction do
          updated_counters_count = insert_counters_records(ids, registered_counters)
          touch_attributes(ids, touch) if touch.present?
        end

        updated_counters_count
      end

      private

      def _slotted_counters
        @_slotted_counters ||= []
      end

      def reset_slotted_counters(id, *counters, touch: nil)
        object = find(id)

        counters.each do |counter_association|
          has_many_association = _reflect_on_association(counter_association)
          raise ArgumentError, "'#{name}' has no association called '#{counter_association}'" unless has_many_association

          counter_name = slotted_counter_name counter_association

          ActiveRecord::Base.transaction do
            counter_value = object.send(counter_association).count(:all)
            updates = {counter_name => counter_value}
            remove_counters_records([id], counter_name)
            insert_counters_records([id], updates)
            touch_attributes([id], touch) if touch.present?
          end
        end
      end

      def insert_counters_records(ids, counters)
        counters_params = prepare_slotted_counters_params(ids, counters)

        ActiveRecordSlottedCounters::SlottedCounter.bulk_insert(counters_params)
      end

      def remove_counters_records(ids, counter_name)
        ActiveRecordSlottedCounters::SlottedCounter.where(
          counter_name: counter_name,
          associated_record_type: name,
          associated_record_id: ids
        ).delete_all
      end

      def touch_attributes(ids, touch)
        scope = unscoped.where(id: ids)
        return scope.touch_all if touch == true

        scope.touch_all(touch)
      end

      def prepare_slotted_counters_params(ids, counters)
        counters.map do |counter_name, count|
          slot = rand(DEFAULT_MAX_SLOT_NUMBER)

          ids.map do |id|
            {
              counter_name: counter_name,
              associated_record_type: name,
              associated_record_id: id,
              slot: slot,
              count: count
            }
          end
        end.flatten
      end
    end

    def increment!(attribute, by = 1, touch: nil)
      return super unless self.class.registered_slotted_counter? attribute

      self.class.update_counters(id, attribute => by, :touch => touch)
    end

    private

    def read_slotted_counter(counter_type)
      association_name = slotted_counter_association_name(counter_type)
      scope = association(association_name).load_target
      scope.sum(&:count)
    end
  end
end
