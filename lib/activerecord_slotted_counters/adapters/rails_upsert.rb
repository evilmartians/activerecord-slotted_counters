# frozen_string_literal: true

module ActiveRecordSlottedCounters
  module Adapters
    class RailsUpsert
      attr_reader :klass, :current_adapter_name

      def initialize(klass)
        @klass = klass
      end

      def apply?
        ActiveRecord::VERSION::MAJOR >= 7
      end

      def bulk_insert(attributes, on_duplicate: nil, unique_by: nil)
        klass.upsert_all(attributes, on_duplicate: on_duplicate, unique_by: unique_by)
      end
    end
  end
end
