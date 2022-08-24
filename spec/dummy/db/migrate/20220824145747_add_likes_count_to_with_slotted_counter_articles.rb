# frozen_string_literal: true

class AddLikesCountToWithSlottedCounterArticles < ActiveRecord::Migration[7.0]
  def change
    add_column :with_slotted_counter_articles, :likes_count, :integer, default: 0, nullable: false
  end
end
