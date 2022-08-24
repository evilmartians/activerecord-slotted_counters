class CreateSlottedCounters < ActiveRecord::Migration[7.0]
  def change
    create_table :slotted_counters do |t|
      t.string :counter_name
      t.string :associated_record_type
      t.integer :associated_record_id
      t.integer :slot
      t.integer :count

      t.timestamps
    end

    add_index :slotted_counters, [:associated_record_id, :associated_record_type, :counter_name, :slot], unique: true, name: 'index_slotted_counters'
  end
end
