# frozen_string_literal: true

require "active_support"
require "activerecord_slotted_counters/utils"
require "activerecord_slotted_counters/pg_insert"

module ActiveRecordSlottedCounters
  class SlottedCounter < ::ActiveRecord::Base
    include ActiveRecordSlottedCounters::PgInsert

    class NotSupportedAdapter < StandardError; end

    scope :associated_records, ->(counter_name, id, klass) do
      where(counter_name: counter_name, associated_record_id: id, associated_record_type: klass)
    end

    # NOTE Rails 6 doesn't support "on_duplicate" option with custom sql
    def self.upsert_all(attributes, on_duplicate: :update, returning: nil, unique_by: nil, record_timestamps: nil)
      return super if ActiveRecord::VERSION::MAJOR >= 7

      postgres_adapter_name = ActiveRecord::ConnectionAdapters::PostgreSQLAdapter::ADAPTER_NAME
      return pg_upsert_all(attributes, on_duplicate: on_duplicate, unique_by: unique_by) if connection.adapter_name == postgres_adapter_name

      raise NotSupportedAdapter, "Gem supports only PostgreSQL"
    end
  end

  module BelongsToAssociation
    def update_counters_via_scope(klass, foreign_key, by)
      counter_name = reflection.counter_cache_column
      super unless klass.registered_slotted_counter? counter_name

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

        has_many association_name, **SLOTTED_COUNTERS_ASSOCIATION_OPTIONS

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

      def insert_counters_records(ids, counters)
        counters_params = prepare_slotted_counters_params(ids, counters)
        on_duplicate_clause = "count = slotted_counters.count + excluded.count"

        result = ActiveRecordSlottedCounters::SlottedCounter.upsert_all(
          counters_params,
          on_duplicate: Arel.sql(on_duplicate_clause),
          unique_by: :index_slotted_counters
        )

        result.rows.count
      end

      def touch_attributes(ids, touch)
        scope = where(id: ids)
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
      super unless self.class.registered_slotted_counter? attribute

      self.class.update_counters(id, attribute => by, :touch => touch)
    end

    private

    def read_slotted_counter(counter_type)
      association_name = slotted_counter_association_name(counter_type)

      if association_cached?(association_name)
        scope = association(association_name).scope
        counter = scope.sum(&:count)

        return counter
      end

      counter_name = slotted_counter_name(counter_type)
      scope = send(association_name).associated_records(counter_name, id, self.class.to_s)
      scope.sum(:count)
    end
  end
end
