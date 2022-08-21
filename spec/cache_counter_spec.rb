require_relative 'spec_helper'

require 'models/article'
require 'models/comment'

RSpec.shared_examples "test ActiveRecord::CounterCache interface" do |article_class, comment_class|
  let(:article_class) { article_class }
  let(:comment_class) { comment_class }

  it "should increment the counter after adding a new comment" do
    article = article_class.create!
    article.comments.create!
    expect(article.comments_count).to eq(1)
  end
end

RSpec.describe "ActiveRecord::CounterCache" do
  include_examples "test ActiveRecord::CounterCache interface", Article, Comment
end
