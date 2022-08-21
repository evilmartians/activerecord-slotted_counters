# frozen_string_literal: true

module ActiveRecordSlottedCounters
  module ClassMethods
    # TODO setup in gem config
    DEFAULT_MAX_SLOT_NUMBER = 100

    def increment_counter(counter_name, id, touch: nil)
      insert_counter_record(counter_name, id, 1)
    end

    def decrement_counter(counter_name, id, touch: nil)
      insert_counter_record(counter_name, id, -1)
    end

    protected

    def insert_counter_record(counter_name, id, count)
      slot = rand(DEFAULT_MAX_SLOT_NUMBER)
      on_duplicate_clause = "count = slotted_counters.count + #{count}"

      SlottedCounter.upsert(
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
    end
  end
end
