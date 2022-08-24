class CreateWithSlottedCounterComments < ActiveRecord::Migration[7.0]
  def change
    create_table :with_slotted_counter_comments do |t|
      t.references :with_slotted_counter_article, null: false, foreign_key: true, index: { name: 'slotted_counter_comments_article_id' }

      t.timestamps
    end
  end
end
