# frozen_string_literal: true

module WithSlottedCounter
  class Like < ActiveRecord::Base
    self.table_name = "with_slotted_counter_likes"

    belongs_to :article, counter_cache: true
  end
end
