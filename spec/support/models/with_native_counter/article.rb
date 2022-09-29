# frozen_string_literal: true

module WithNativeCounter
  class Article < ActiveRecord::Base
    self.table_name = "with_native_counter_articles"

    has_many :comments, class_name: "WithNativeCounter::Comment", foreign_key: "with_native_counter_article_id"

    has_many :views, as: :viewable
  end
end
