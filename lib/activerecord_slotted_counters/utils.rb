# frozen_string_literal: true

require "active_support"

module ActiveRecordSlottedCounters
  module Utils
    private

    def slotted_counter_association_name(counter_type)
      "#{counter_type}_slotted_counters".to_sym
    end

    def slotted_counter_name(counter_type)
      "#{counter_type}_count".to_sym
    end

    # TODO refactoring
    def slotted_counter_type(counter_name)
      counter_name.to_s.split("_")[0..-2].join("_").to_sym
    end

    def after_add_method_name(counter_type)
      "increment_#{counter_type}".to_sym
    end

    def after_remove_method_name(counter_type)
      "decrement_#{counter_type}".to_sym
    end
  end
end
