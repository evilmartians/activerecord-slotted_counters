# frozen_string_literal: true

ActiveRecord::Schema.define do
  create_table "with_native_counter_articles", force: true do |t|
    t.integer "comments_count", default: 0, null: false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "with_native_counter_comments", force: true do |t|
    t.integer "with_native_counter_article_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "with_slotted_counter_articles", force: true do |t|
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "with_slotted_counter_comments", force: true do |t|
    t.integer "with_slotted_counter_article_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "slotted_counters", force: true do |t|
    t.string "counter_name"
    t.string "associated_record_type"
    t.integer "associated_record_id"
    t.integer "slot"
    t.integer "count"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["slot", "counter_name", "associated_record_type", "associated_record_id"], name: "index_slotted_counters", unique: true
  end
end
