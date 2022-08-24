# frozen_string_literal: true

require_relative "spec_helper"

RSpec.describe "ActiveRecord::SlottedCounterCache", :db do
  it_behaves_like "ActiveRecord::CounterCache interface", WithSlottedCounter::Article, WithSlottedCounter::Comment
  it_behaves_like "ActiveRecord::CounterCache interface", WithNativeCounter::Article, WithNativeCounter::Comment

  context "counter requests more than max slot number" do
    let(:more_than_max_slotted_count) { 101 }

    it "increments counter" do
      article = WithSlottedCounter::Article.create!

      more_than_max_slotted_count.times do
        WithSlottedCounter::Article.increment_counter(:comments_count, article.id)
      end
      expect(article.comments_count).to eq(more_than_max_slotted_count)
    end

    it "decrements counter" do
      article = WithSlottedCounter::Article.create!

      more_than_max_slotted_count.times do
        WithSlottedCounter::Article.decrement_counter(:comments_count, article.id)
      end
      expect(article.comments_count).to eq(-more_than_max_slotted_count)
    end
  end

  describe "using both counter types simultaneously" do
    it "should use native counter increment method" do
      article = WithSlottedCounter::Article.create!

      WithSlottedCounter::Article.increment_counter(:likes_count, article.id)
      # TODO read from with_slotted_counter_articles.likes_count column directly
      article.reload

      expect(article.likes_count).to eq(1)
    end
  end
end
