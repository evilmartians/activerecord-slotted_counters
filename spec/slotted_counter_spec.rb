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

  it "does not generate N+1 queries" do
    WithSlottedCounter::Article.create!
    WithSlottedCounter::Article.create!

    expect {
      WithSlottedCounter::Article.all.with_slotted_counters(:comments).find_each { _1.comments_count }
    }.not_to exceed_query_limit(2).with(/SELECT/)
  end

  def insert_association_sql(association_class, article_id)
    association_table = association_class.arel_table
    foreign_key = association_class.reflections["article"].foreign_key
    current_date_sql_command =
      if defined?(ActiveRecord::ConnectionAdapters::SQLite3Adapter)
        "date('now')"
      else
        "now()"
      end

    insert_manager = Arel::InsertManager.new
    insert_manager.insert([
      [association_table[foreign_key], article_id],
      [association_table[:created_at], Arel.sql(current_date_sql_command)],
      [association_table[:updated_at], Arel.sql(current_date_sql_command)]
    ])

    insert_manager.to_sql
  end

  it "uses unscoped Active Record lookups when touch:true is used" do
    article = WithSlottedCounter::DefaultScope.create!
    expect(article.published).to be true
    sql_output = []

    ActiveSupport::Notifications.subscribe("sql.active_record") do |_, _, _, _, details|
      sql_output << details[:sql]
    end

    WithSlottedCounter::DefaultScope.update_counters(article.id, comments_count: 1, touch: true)

    ActiveSupport::Notifications.unsubscribe("sql.active_record")
    expect(sql_output.any? { |sql| sql.include?("published = true") }).to be_falsey
  end
end
