# frozen_string_literal: true

module ActiveRecordSlottedCounters
  SLOTTED_COUNTERS_TABLE_NAME = :slotted_counters

  class ActiveRecordSlottedCounters::NotSupportedAdapter < StandardError; end

  class SlottedCounter < ::ActiveRecord::Base
    self.table_name = SLOTTED_COUNTERS_TABLE_NAME

    def self.upsert(attributes, **options)
      raise ActiveRecordSlottedCounters::NotSupportedAdapter unless connection.adapter_name == "PostgreSQL"

      pg_upsert(attributes, options)
    end

    def self.pg_upsert(attributes, options)
      sql = raw_pg_upsert_sql(attributes, options)
      pg_result = connection.execute(sql)
      pg_result.cmd_tuples
    end

    # TODO refactoring
    def self.raw_pg_upsert_sql(attributes, options)
      <<-SQL.squish
        INSERT INTO "slotted_counters"
        ("counter_name","associated_record_type","associated_record_id","slot","count","created_at","updated_at")
        VALUES (
          '#{attributes[:counter_name]}',
          '#{attributes[:associated_record_type]}',
          #{attributes[:associated_record_id]},
          #{attributes[:slot]},
          #{attributes[:count]},
          CURRENT_TIMESTAMP,
          CURRENT_TIMESTAMP)
        ON CONFLICT("slot","counter_name","associated_record_type","associated_record_id")
        DO UPDATE SET #{options[:on_duplicate]}
        RETURNING id;
      SQL
    end
  end
end
