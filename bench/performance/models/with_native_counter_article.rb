# frozen_string_literal: true

class WithNativeCounterArticle < ActiveRecord::Base
  self.table_name = "with_native_counter_articles"

  has_many :comments
end
