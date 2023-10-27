# frozen_string_literal: true

module ActiveRecordSlottedCounters
  module Adapters
    class RailsUpsert
      attr_reader :klass

      def initialize(klass)
        @klass = klass
      end

      def apply?(_)
        ActiveRecord::VERSION::MAJOR >= 7
      end

      def bulk_insert(attributes, on_duplicate: nil, unique_by: nil)
        klass.upsert_all(attributes, on_duplicate: on_duplicate, unique_by: unique_by).rows.count
      end

      def wrap_column_name(value)
        "EXCLUDED.#{value}"
      end
    end
  end
end
