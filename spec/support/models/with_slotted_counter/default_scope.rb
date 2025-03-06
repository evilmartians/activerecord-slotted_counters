# frozen_string_literal: true

module WithSlottedCounter
  class DefaultScope < Article
    self.table_name = "with_slotted_counter_articles"
    default_scope { where(published: true) }
    attribute :published, :boolean, default: false
  end
end
