# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 2019_05_12_190744) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "orders", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.integer "server_from_id", null: false
    t.integer "server_to_id", null: false
    t.string "url", null: false
    t.integer "url_type", null: false
    t.integer "url_id", null: false
    t.boolean "finished", null: false
  end

  create_table "receipts", force: :cascade do |t|
    t.bigint "order_id", null: false
    t.integer "result", null: false
    t.string "message"
    t.index ["order_id"], name: "index_receipts_on_order_id"
  end

  create_table "servers", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "domain", null: false
    t.integer "api_type", null: false
    t.string "username", null: false
    t.string "auth", null: false
  end

  create_table "users", force: :cascade do |t|
    t.string "name", null: false
    t.string "encrypted_password", null: false
  end

end
