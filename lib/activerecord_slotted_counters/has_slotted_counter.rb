# frozen_string_literal: true

require "active_support"
require "activerecord_slotted_counters/utils"

module ActiveRecordSlottedCounters
  class SlottedCounter < ::ActiveRecord::Base
    scope :associated_records, ->(counter_name, id, klass) do
      where(counter_name: counter_name, associated_record_id: id, associated_record_type: klass)
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
    }.freeze

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

      def increment_counter(counter_name, id, touch: nil)
        return super unless registered_slotted_counter? counter_name

        insert_counter_record(counter_name, id, 1)
      end

      def decrement_counter(counter_name, id, touch: nil)
        return super unless registered_slotted_counter? counter_name

        insert_counter_record(counter_name, id, -1)
      end

      def slotted_counters
        if superclass.respond_to?(:slotted_counters)
          superclass.slotted_counters + _slotted_counters
        else
          _slotted_counters
        end
      end

      private

      def _slotted_counters
        @_slotted_counters ||= []
      end

      def registered_slotted_counter?(counter_name)
        counter_type = slotted_counter_type(counter_name)

        slotted_counters.include? counter_type
      end

      def insert_counter_record(counter_name, id, count)
        slot = rand(DEFAULT_MAX_SLOT_NUMBER)
        on_duplicate_clause = "count = slotted_counters.count + #{count}"

        result = ActiveRecordSlottedCounters::SlottedCounter.upsert(
          {
            counter_name: counter_name,
            associated_record_type: name,
            associated_record_id: id,
            slot: slot,
            count: count
          },
          on_duplicate: Arel.sql(on_duplicate_clause),
          unique_by: :index_slotted_counters
        )

        result.rows.count
      end
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
