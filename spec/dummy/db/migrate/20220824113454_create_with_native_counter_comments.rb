class CreateWithNativeCounterComments < ActiveRecord::Migration[7.0]
  def change
    create_table :with_native_counter_comments do |t|
      t.references :with_native_counter_article, null: false, foreign_key: true, index: { name: 'native_counter_article_id' }

      t.timestamps
    end
  end
end
