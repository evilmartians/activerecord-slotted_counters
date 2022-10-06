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

    it "should reset native and slotted counters" do
      article = WithSlottedCounter::Article.create!

      sql = insert_association_sql(WithSlottedCounter::Like, article.id)
      ActiveRecord::Base.connection.execute(sql)

      sql = insert_association_sql(WithSlottedCounter::Comment, article.id)
      ActiveRecord::Base.connection.execute(sql)

      article.reload

      expect(article.likes_count).to eq(0)
      expect(article.comments_count).to eq(0)

      WithSlottedCounter::Article.reset_counters(article.id, :likes, :comments)
      article.reload

      expect(article.likes_count).to eq(1)
      expect(article.comments_count).to eq(1)
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

  it "must update multiple counters in model" do
    article = WithSlottedCounter::Article.create!

    comments_count = rand(10)
    views_count = rand(10)

    WithSlottedCounter::Article.update_counters(article.id, comments_count: comments_count, views_count: views_count)

    expect(article.comments_count).to eq(comments_count)
    expect(article.views_count).to eq(views_count)
  end

  it "must preload slotted counters" do
    article = WithSlottedCounter::Article.create!
    WithSlottedCounter::Article.increment_counter(:comments_count, article.id)

    WithSlottedCounter::Article.all.find_each do |article|
      expect(article.comments_slotted_counters.loaded?).to be_falsy
    end

    WithSlottedCounter::Article.all.with_slotted_counters(:comments).find_each do |article|
      expect(article.comments_slotted_counters.loaded?).to be_truthy
    end
  end

  def insert_association_sql(association_class, article_id)
    association_table = association_class.arel_table
    foreign_key = association_class.reflections["article"].foreign_key
    insert_manager = Arel::InsertManager.new
    insert_manager.insert([
      [association_table[foreign_key], article_id],
      [association_table[:created_at], Arel.sql("now()")],
      [association_table[:updated_at], Arel.sql("now()")]
    ])

    insert_manager.to_sql
  end
end
