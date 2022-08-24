# frozen_string_literal: true

module WithSlottedCounter
  class SpecificArticle < Article
    self.table_name = "with_slotted_counter_specific_articles"

    has_slotted_counter :specific_comments
  end
end
