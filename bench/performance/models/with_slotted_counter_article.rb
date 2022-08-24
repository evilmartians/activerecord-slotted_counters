# frozen_string_literal: true

class WithSlottedCounterArticle < ActiveRecord::Base
  self.table_name = "with_slotted_counter_articles"

  has_slotted_counter :comments
end
