# frozen_string_literal: true

module ActiveRecordSlottedCounters
  module Adapters
    class MysqlUpsert
      attr_reader :klass

      def initialize(klass, **)
        @klass = klass
      end

      def apply?(current_adapter_name)
        return false unless defined?(ActiveRecord::ConnectionAdapters::Mysql2Adapter)

        current_adapter_name == ActiveRecord::ConnectionAdapters::Mysql2Adapter::ADAPTER_NAME
      end

      def bulk_insert(attributes, on_duplicate: nil, **)
        raise ArgumentError, "Values must not be empty" if attributes.empty?

        keys = attributes.first.keys + klass.all_timestamp_attributes_in_model

        current_time = klass.current_time_from_proper_timezone
        data = attributes.map { |attr| attr.values + [current_time, current_time] }

        columns = columns_for_attributes(keys)

        fields_str = quote_column_names(columns)
        values_str = quote_many_records(columns, data)

        sql = <<~SQL
          INSERT INTO #{klass.quoted_table_name}
          (#{fields_str})
          VALUES #{values_str}
        SQL

        if on_duplicate.present?
          sql += " ON DUPLICATE KEY UPDATE #{on_duplicate};"
        end

        # insert/update and return amount of updated rows
        klass.connection.update(sql)
      end

      def wrap_column_name(value)
        "VALUES(#{value})"
      end

      private

      def columns_for_attributes(attributes)
        attributes.map do |attribute|
          klass.column_for_attribute(attribute)
        end
      end

      def quote_column_names(columns, table_name: false)
        columns.map do |column|
          column_name = klass.connection.quote_column_name(column.name)

          if table_name
            "#{klass.quoted_table_name}.#{column_name}"
          else
            column_name
          end
        end.join(",")
      end

      def quote_record(columns, record_values)
        values_str = record_values.each_with_index.map do |value, i|
          type = klass.connection.lookup_cast_type_from_column(columns[i])
          klass.connection.quote(type.serialize(value))
        end.join(",")

        "(#{values_str})"
      end

      def quote_many_records(columns, data)
        data.map { |values| quote_record(columns, values) }.join(",")
      end
    end
  end
end
