# frozen_string_literal: true

require "benchmark"
require "active_record"
require "activerecord-slotted_counters"
require_relative "../active_record_init"

ActiveRecord::Base.include ActiveRecordSlottedCounters::HasSlottedCounter

require_relative "../models/with_native_counter_article"
require_relative "../models/with_slotted_counter_article"

with_slotted_counter_article = WithSlottedCounterArticle.create!
with_native_counter_article = WithNativeCounterArticle.create!

THREAD_COUNT = 30
ITERATION_COUNT = 1_000

Benchmark.bmbm do |x|
  x.report("Native Counter") do
    THREAD_COUNT.times.map do
      Thread.new do
        ITERATION_COUNT.times do
          WithNativeCounterArticle.increment_counter(:comments_count, with_native_counter_article.id)
        end
      end
    end.each(&:join)
  end

  x.report("Slotted Counter") do
    THREAD_COUNT.times.map do
      Thread.new do
        ITERATION_COUNT.times do
          WithSlottedCounterArticle.increment_counter(:comments_count, with_slotted_counter_article.id)
        end
      end
    end.each(&:join)
  end
end
