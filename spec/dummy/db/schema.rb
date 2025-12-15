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

ActiveRecord::Schema[8.1].define(version: 2025_12_15_040110) do
  create_table "active_storage_attachments", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.bigint "record_id", null: false
    t.string "record_type", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.string "content_type"
    t.datetime "created_at", null: false
    t.string "filename", null: false
    t.string "key", null: false
    t.text "metadata"
    t.string "service_name", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "darwin_articles", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "dob"
    t.date "jj"
    t.datetime "party"
    t.integer "person_id"
    t.integer "product_id"
    t.text "title"
    t.datetime "updated_at", null: false
    t.boolean "yo"
  end

  create_table "darwin_blocks", force: :cascade do |t|
    t.json "args", default: {}
    t.text "body"
    t.datetime "created_at", null: false
    t.string "method_name", null: false
    t.bigint "model_id", null: false
    t.json "options", default: {}
    t.integer "position", default: 0
    t.datetime "updated_at", null: false
    t.index ["model_id"], name: "index_darwin_blocks_on_model_id"
  end

  create_table "darwin_columns", force: :cascade do |t|
    t.string "column_type"
    t.datetime "created_at", null: false
    t.string "default"
    t.integer "limit"
    t.integer "model_id", null: false
    t.string "name", null: false
    t.boolean "null", default: true
    t.integer "precision"
    t.integer "scale"
    t.datetime "updated_at", null: false
    t.index ["model_id"], name: "index_darwin_columns_on_model_id"
  end

  create_table "darwin_models", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.datetime "updated_at", null: false
  end

  create_table "darwin_people", force: :cascade do |t|
    t.boolean "a"
    t.boolean "aaa"
    t.datetime "created_at", null: false
    t.date "dob"
    t.datetime "updated_at", null: false
    t.text "yo"
  end

  create_table "darwin_products", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "title"
    t.datetime "updated_at", null: false
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "darwin_blocks", "darwin_models", column: "model_id"
  add_foreign_key "darwin_columns", "darwin_models", column: "model_id"
end
