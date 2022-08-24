# frozen_string_literal: true

require "active_support"

module ActiveRecordSlottedCounters
  class SlottedCounter < ::ActiveRecord::Base; end

  module HasSlottedCounter
    extend ActiveSupport::Concern

    # TODO setup in gem config
    DEFAULT_MAX_SLOT_NUMBER = 100

    class_methods do
      def has_slotted_counter(counter_type)
        slotted_counter_types << counter_type

        counter_name = "#{counter_type}_count"
        define_method(counter_name) do
          read_slotted_counter(counter_name)
        end
      end

      def increment_counter(counter_name, id, touch: nil)
        return super unless registered? counter_name

        insert_counter_record(counter_name, id, 1)
      end

      def decrement_counter(counter_name, id, touch: nil)
        return super unless registered? counter_name

        insert_counter_record(counter_name, id, -1)
      end

      private

      def slotted_counter_types
        unless class_variable_defined?(:@@slotted_counters)
          class_variable_set(:@@slotted_counters, Set.new)
        end

        class_variable_get(:@@slotted_counters)
      end

      def registered?(counter_name)
        # TODO think about refactoring
        counter_type = counter_name.to_s.split('_')[0].to_sym

        slotted_counter_types.include? counter_type
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

    # TODO think about cache
    def read_slotted_counter(counter_name)
      ActiveRecordSlottedCounters::SlottedCounter.where(
        counter_name: counter_name,
        associated_record_id: id,
        associated_record_type: self.class.to_s
      ).sum(:count)
    end
  end
end
