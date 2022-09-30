# frozen_string_literal: true

module WithNativeCounter
  class Comment < ActiveRecord::Base
    self.table_name = "with_native_counter_comments"

    belongs_to :article, counter_cache: true, class_name: "WithNativeCounter::Article", foreign_key: :with_native_counter_article_id
  end
end
