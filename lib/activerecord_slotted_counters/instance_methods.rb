# frozen_string_literal: true

module ActiveRecordSlottedCounters
  module InstanceMethods
    def read_slotted_counter(counter_name)
      @slotted_counters_cache ||= {}
      @slotted_counters_cache[counter_name] ||= ActiveRecordSlottedCounters::SlottedCounter.where(
        counter_name: counter_name,
        associated_record_id: id,
        associated_record_type: self.class.to_s
      ).sum(:count)
    end
  end
end
