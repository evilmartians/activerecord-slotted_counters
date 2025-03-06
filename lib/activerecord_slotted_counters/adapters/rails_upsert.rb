# frozen_string_literal: true

module ActiveRecordSlottedCounters
  module Adapters
    class RailsUpsert
      attr_reader :klass, :supports_insert_conflict_target

      def initialize(klass, supports_insert_conflict_target: false)
        @klass = klass
        @supports_insert_conflict_target = supports_insert_conflict_target
      end

      def apply?(_)
        ActiveRecord::VERSION::MAJOR >= 7
      end

      def bulk_insert(attributes, on_duplicate: nil, unique_by: nil)
        opts = {on_duplicate: on_duplicate, unique_by: unique_by}
        opts.delete(:unique_by) unless supports_insert_conflict_target

        klass.with_connection do |c|
          # We have to manually call #update here to return the number of affected rows
          c.update(ActiveRecord::InsertAll.new(klass.all, c, attributes, **opts).send(:to_sql))
        end
      end

      def wrap_column_name(value)
        # This is mysql
        if !supports_insert_conflict_target
          "VALUES(#{value})"
        else
          "EXCLUDED.#{value}"
        end
      end
    end
  end
end
