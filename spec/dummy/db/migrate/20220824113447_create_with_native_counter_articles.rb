class CreateWithNativeCounterArticles < ActiveRecord::Migration[7.0]
  def change
    create_table :with_native_counter_articles do |t|
      t.integer :comments_count, default: 0, nullable: false

      t.timestamps
    end
  end
end
