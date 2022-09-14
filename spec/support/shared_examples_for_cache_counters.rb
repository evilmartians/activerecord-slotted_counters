# frozen_string_literal: true

RSpec.shared_examples "ActiveRecord::CounterCache interface" do |article_class, comment_class|
  let(:article_class) { article_class }
  let(:comment_class) { comment_class }

  it "increments counter by increment_counter call" do
    article = article_class.create!
    updated_rows_count = article_class.increment_counter(:comments_count, article.id)
    article.reload
    expect(article.comments_count).to eq(1)
    expect(updated_rows_count).to eq(1)
  end

  it "decrements counter by decrement_counter call" do
    article = article_class.create!
    updated_rows_count = article_class.decrement_counter(:comments_count, article.id)
    article.reload
    expect(article.comments_count).to eq(-1)
    expect(updated_rows_count).to eq(1)
  end

  it "increments counter after adding a new comment" do
    skip "TODO waits belongs_to support"
    article = article_class.create!
    article.comments.create!
    expect(article.comments_count).to eq(1)
  end

  describe "update_counters interface" do
    it "updates counter by passing id as integer" do
      article = article_class.create!
      updated_rows_count = article_class.update_counters(article.id, comments_count: 1)
      article.reload
      expect(article.comments_count).to eq(1)
      expect(updated_rows_count).to eq(1)
    end

    it "updates counter by passing id as array" do
      article = article_class.create!
      updated_rows_count = article_class.update_counters([article.id], comments_count: 1)
      article.reload
      expect(article.comments_count).to eq(1)
      expect(updated_rows_count).to eq(1)
    end

    it "must not update 'updated_at' without 'touch' option" do
      article = article_class.create!
      previous_updated_at = article.updated_at

      article_class.update_counters(article.id, comments_count: 1)

      article.reload
      expect(article.updated_at).to eq(previous_updated_at)
    end

    it "must update 'updated_at' with 'touch' option" do
      article = article_class.create!
      previous_updated_at = article.updated_at

      article_class.update_counters(article.id, comments_count: 1, touch: true)

      article.reload
      expect(article.updated_at).not_to eq(previous_updated_at)
    end

    it "must update specific datetime field with 'touch' option" do
      article = article_class.create!
      previous_specific_updated_at = article.specific_updated_at

      article_class.update_counters(article.id, comments_count: 1, touch: :specific_updated_at)

      article.reload
      expect(article.specific_updated_at).not_to eq(previous_specific_updated_at)
    end
  end

  it "changes counter after creating and destroying comments" do
    article = article_class.create!
    article.comments.create!
    expect(article.comments_count).to eq(1)

    article.comments.destroy_all

    article.reload
    expect(article.comments_count).to eq(0)
  end
end
