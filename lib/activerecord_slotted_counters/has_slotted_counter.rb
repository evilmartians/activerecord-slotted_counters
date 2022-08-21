# frozen_string_literal: true

require "active_support"

module ActiveRecordSlottedCounters
  module HasSlottedCounter
    extend ActiveSupport::Concern

    module ClassMethods
      def has_slotted_counter(counter_name)
        # FIXME prepend only if not already prepended
        singleton_class.prepend ActiveRecordSlottedCounters::ClassMethods
        prepend ActiveRecordSlottedCounters::InstanceMethods

        @registered_slotted_counters ||= []
        # FIXME check uniqness
        @registered_slotted_counters << counter_name

        define_method("#{counter_name}_count") do
          read_slotted_counter("#{counter_name}_count")
        end
      end

      def registered_slotted_counters
        @registered_slotted_counters
      end
    end
  end
end
