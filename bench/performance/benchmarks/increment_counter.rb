# frozen_string_literal: true

require "benchmark"
require File.expand_path("../config/environment", __dir__)

with_slotted_counter_article = WithSlottedCounter::Article.create!
with_native_counter_article = WithNativeCounter::Article.create!

THREAD_COUNT = 30
ITERATION_COUNT = 1_000

Benchmark.bmbm do |x|
  x.report("Native Counter") do
    THREAD_COUNT.times.map do
      Thread.new do
        ITERATION_COUNT.times do
          WithNativeCounter::Article.increment_counter(:comments_count, with_native_counter_article.id)
        end
      end
    end.each(&:join)
  end

  x.report("Slotted Counter") do
    THREAD_COUNT.times.map do
      Thread.new do
        ITERATION_COUNT.times do
          WithSlottedCounter::Article.increment_counter(:comments_count, with_slotted_counter_article.id)
        end
      end
    end.each(&:join)
  end
end
