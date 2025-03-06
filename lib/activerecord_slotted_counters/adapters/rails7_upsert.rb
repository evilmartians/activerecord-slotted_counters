# frozen_string_literal: true

module ActiveRecordSlottedCounters
  module Adapters
    class Rails7Upsert < RailsUpsert
      def apply?(_)
        ActiveRecord::VERSION::MAJOR == 7 && ActiveRecord::VERSION::MINOR < 2
      end

      def bulk_insert(attributes, on_duplicate: nil, unique_by: nil)
        opts = {on_duplicate: on_duplicate, unique_by: unique_by}
        opts.delete(:unique_by) unless supports_insert_conflict_target

        # We have to manually call #update here to return the number of affected rows.
        # In Rails <7.2, connection is obtained internally.
        ActiveRecord::InsertAll.new(klass, attributes, **opts).then do |inserter|
          inserter.send(:connection).update(inserter.send(:to_sql))
        end
      end
    end
  end
end
