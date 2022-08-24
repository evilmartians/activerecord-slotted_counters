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
    it "should use native counter" do
      article = WithSlottedCounter::Article.create!

      WithSlottedCounter::Article.increment_counter(:likes_count, article.id)
      likes_count = WithSlottedCounter::Article.where(id: article.id).pluck(:likes_count).first

      expect(likes_count).to eq(1)
    end
  end

  describe "using slotted counter in child model" do
    it "should use parent slotted counter" do
      article = WithSlottedCounter::SpecificArticle.create!

      WithSlottedCounter::SpecificArticle.increment_counter(:comments_count, article.id)

      expect(article.comments_count).to eq(1)
    end

    it "should use specific slotted counter" do
      article = WithSlottedCounter::SpecificArticle.create!

      WithSlottedCounter::SpecificArticle.increment_counter(:specific_comments_count, article.id)

      expect(article.specific_comments_count).to eq(1)
    end
  end
end
