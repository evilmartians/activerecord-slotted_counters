class CreateWithSlottedCounterLikes < ActiveRecord::Migration[7.0]
  def change
    create_table :with_slotted_counter_likes do |t|
      t.references :with_slotted_counter_article, null: false, foreign_key: true, index: { name: 'slotted_counter_likes_article_id' }

      t.timestamps
    end
  end
end
