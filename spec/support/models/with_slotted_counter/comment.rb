# frozen_string_literal: true

module WithSlottedCounter
  class Comment < ActiveRecord::Base
    self.table_name = "with_slotted_counter_comments"

    belongs_to :article, counter_cache: true, class_name: "WithSlottedCounter::Article", foreign_key: :with_slotted_counter_article_id
  end
end
