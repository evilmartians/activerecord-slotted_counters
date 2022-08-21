# frozen_string_literal: true

module WithSlottedCounter
  class Comment < ActiveRecord::Base
    self.table_name = "with_slotted_counter_comments"

    belongs_to :article, counter_cache: true
  end
end
