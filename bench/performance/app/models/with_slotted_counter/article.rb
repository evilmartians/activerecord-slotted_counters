# frozen_string_literal: true

module WithSlottedCounter
  class Article < ActiveRecord::Base
    self.table_name = "with_slotted_counter_articles"

    has_many :comments, class_name: "WithSlottedCounter::Comment", foreign_key: "with_slotted_counter_article_id"
    has_slotted_counter :comments
  end
end
