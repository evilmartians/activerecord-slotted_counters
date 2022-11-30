# frozen_string_literal: true

require "activerecord_slotted_counters/quote_record"

module ActiveRecordSlottedCounters
  module PgInsert
    extend ActiveSupport::Concern
    include QuoteRecord

    module ClassMethods
      def pg_upsert_all(attributes, on_duplicate: nil, unique_by: nil)
        raise ArgumentError, "Values must not be empty" if attributes.empty?

        keys = attributes.first.keys + all_timestamp_attributes_in_model

        current_time = current_time_from_proper_timezone
        data = attributes.map { |attr| attr.values + [current_time, current_time] }

        columns = columns_for_attributes(keys)

        fields_str = quote_column_names(columns)
        values_str = quote_many_records(columns, data)

        sql = <<~SQL
          INSERT INTO #{quoted_table_name}
          (#{fields_str})
          VALUES #{values_str}
        SQL

        if unique_by.present?
          index = unique_indexes.find { |i| i.name.to_sym == unique_by }
          columns = columns_for_attributes(index.columns)
          fields = quote_column_names(columns)

          sql << " ON CONFLICT (#{fields})"
        end

        if on_duplicate.present?
          sql << " DO UPDATE SET #{on_duplicate}"
        end

        sql << " RETURNING \"id\""

        connection.exec_query(sql)
      end

      private

      def unique_indexes
        connection.schema_cache.indexes(table_name).select(&:unique)
      end
    end
  end
end
