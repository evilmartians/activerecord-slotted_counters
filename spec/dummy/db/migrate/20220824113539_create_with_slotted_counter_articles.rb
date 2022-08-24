class CreateWithSlottedCounterArticles < ActiveRecord::Migration[7.0]
  def change
    create_table :with_slotted_counter_articles do |t|

      t.timestamps
    end
  end
end
