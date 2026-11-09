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

ActiveRecord::Schema[8.1].define(version: 2026_11_10_000002) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "chats", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.boolean "deleted", default: false, null: false
    t.text "description"
    t.string "kind", default: "group", null: false
    t.string "name", null: false
    t.datetime "updated_at", null: false
    t.index ["deleted"], name: "index_chats_on_deleted"
  end

  create_table "employees", force: :cascade do |t|
    t.text "bio"
    t.datetime "created_at", null: false
    t.boolean "deleted", default: false, null: false
    t.string "department", null: false
    t.string "email", null: false
    t.string "name", null: false
    t.datetime "updated_at", null: false
    t.index ["deleted"], name: "index_employees_on_deleted"
    t.index ["email"], name: "index_employees_on_email", unique: true
  end

  create_table "memberships", force: :cascade do |t|
    t.bigint "chat_id", null: false
    t.datetime "created_at", null: false
    t.boolean "deleted", default: false, null: false
    t.bigint "employee_id", null: false
    t.datetime "last_read_at"
    t.boolean "muted", default: false, null: false
    t.string "role", default: "member", null: false
    t.datetime "updated_at", null: false
    t.index ["chat_id"], name: "index_memberships_on_chat_id"
    t.index ["deleted"], name: "index_memberships_on_deleted"
    t.index ["employee_id", "chat_id"], name: "unique_active_chat_membership", unique: true, where: "(deleted = false)"
    t.index ["employee_id"], name: "index_memberships_on_employee_id"
  end

  create_table "messages", force: :cascade do |t|
    t.text "body", null: false
    t.bigint "chat_id", null: false
    t.datetime "created_at", null: false
    t.boolean "deleted", default: false, null: false
    t.bigint "employee_id", null: false
    t.datetime "updated_at", null: false
    t.index ["chat_id", "created_at"], name: "index_messages_on_chat_id_and_created_at"
    t.index ["chat_id"], name: "index_messages_on_chat_id"
    t.index ["deleted"], name: "index_messages_on_deleted"
    t.index ["employee_id"], name: "index_messages_on_employee_id"
  end

  add_foreign_key "memberships", "chats"
  add_foreign_key "memberships", "employees"
  add_foreign_key "messages", "chats"
  add_foreign_key "messages", "employees"
end
