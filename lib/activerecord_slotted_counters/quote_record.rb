# frozen_string_literal: true

module ActiveRecordSlottedCounters
  module QuoteRecord
    extend ActiveSupport::Concern

    module ClassMethods
      def columns_for_attributes(attributes)
        attributes.map do |attribute|
          column_for_attribute(attribute)
        end
      end

      def quote_column_names(columns, table_name: false)
        columns.map do |column|
          column_name = connection.quote_column_name(column.name)
          if table_name
            "#{quoted_table_name}.#{column_name}"
          else
            column_name
          end
        end.join(",")
      end

      def quote_record(columns, record_values)
        values_str = record_values.each_with_index.map do |value, i|
          type = connection.lookup_cast_type_from_column(columns[i])
          connection.quote(type.serialize(value))
        end.join(",")
        "(#{values_str})"
      end

      def quote_many_records(columns, data)
        data.map { |values| quote_record(columns, values) }.join(",")
      end
    end
  end
end
