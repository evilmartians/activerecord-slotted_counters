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
    it "should increment native counter" do
      article = WithSlottedCounter::Article.create!

      WithSlottedCounter::Article.increment_counter(:likes_count, article.id)
      likes_count = WithSlottedCounter::Article.where(id: article.id).pluck(:likes_count).first

      expect(likes_count).to eq(1)
    end

    it "should update native and slotted counters" do
      article = WithSlottedCounter::Article.create!

      likes_count = rand(10)
      comments_count = rand(10)

      WithSlottedCounter::Article.update_counters(article.id, likes_count: likes_count, comments_count: comments_count)
      article.reload

      expect(article.likes_count).to eq(likes_count)
      expect(article.comments_count).to eq(comments_count)
    end

    # TODO move to shared_examples after adding touch support for slotted counter
    it "must not update 'updated_at' without 'touch' option" do
      article = WithSlottedCounter::Article.create!
      previous_updated_at = article.updated_at

      WithSlottedCounter::Article.update_counters(article.id, likes_count: 1)

      article.reload
      expect(article.updated_at).to eq(previous_updated_at)
    end

    # TODO move to shared_examples after adding touch support for slotted counter
    it "must update 'updated_at' with 'touch' option" do
      article = WithSlottedCounter::Article.create!
      previous_updated_at = article.updated_at

      WithSlottedCounter::Article.update_counters(article.id, likes_count: 1, touch: true)

      article.reload
      expect(article.updated_at).not_to eq(previous_updated_at)
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

  # TODO move to shared_examples after adding `counter_cache: true` support for slotted counter
  describe "native Rails counter" do
    it "changes counter after creating and destroying comments" do
      article = WithNativeCounter::Article.create!
      article.comments.create!
      expect(article.comments_count).to eq(1)

      article.comments.first.destroy
      article.reload
      expect(article.comments_count).to eq(0)
    end
  end
end
