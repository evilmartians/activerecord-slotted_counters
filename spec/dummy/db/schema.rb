# frozen_string_literal: true

# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[7.0].define(version: 2022_08_24_145747) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "slotted_counters", force: :cascade do |t|
    t.string "counter_name"
    t.string "associated_record_type"
    t.integer "associated_record_id"
    t.integer "slot"
    t.integer "count"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["associated_record_id", "associated_record_type", "counter_name", "slot"], name: "index_slotted_counters", unique: true
  end

  create_table "with_native_counter_articles", force: :cascade do |t|
    t.integer "comments_count", default: 0
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "with_native_counter_comments", force: :cascade do |t|
    t.bigint "with_native_counter_article_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["with_native_counter_article_id"], name: "native_counter_article_id"
  end

  create_table "with_slotted_counter_articles", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "likes_count", default: 0
  end

  create_table "with_slotted_counter_comments", force: :cascade do |t|
    t.bigint "with_slotted_counter_article_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["with_slotted_counter_article_id"], name: "slotted_counter_comments_article_id"
  end

  create_table "with_slotted_counter_likes", force: :cascade do |t|
    t.bigint "with_slotted_counter_article_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["with_slotted_counter_article_id"], name: "slotted_counter_likes_article_id"
  end

  add_foreign_key "with_native_counter_comments", "with_native_counter_articles"
  add_foreign_key "with_slotted_counter_comments", "with_slotted_counter_articles"
  add_foreign_key "with_slotted_counter_likes", "with_slotted_counter_articles"
end
