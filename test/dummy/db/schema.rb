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

ActiveRecord::Schema[8.1].define(version: 2025_10_25_000004) do
  create_table "support_chat_conversations", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "guest_email", null: false
    t.string "guest_name", null: false
    t.datetime "last_message_at", precision: nil
    t.string "page_url"
    t.string "session_token", null: false
    t.string "status", default: "open", null: false
    t.datetime "updated_at", null: false
    t.index ["last_message_at"], name: "index_support_chat_conversations_on_last_message_at"
    t.index ["session_token"], name: "index_support_chat_conversations_on_session_token", unique: true
    t.index ["status"], name: "index_support_chat_conversations_on_status"
  end

  create_table "support_chat_messages", force: :cascade do |t|
    t.bigint "agent_id"
    t.text "content", null: false
    t.integer "conversation_id", null: false
    t.datetime "created_at", null: false
    t.boolean "read_by_agent", default: false
    t.boolean "read_by_guest", default: false
    t.string "sender_type", null: false
    t.datetime "updated_at", null: false
    t.index ["conversation_id", "created_at"], name: "index_support_chat_messages_on_conversation_id_and_created_at"
    t.index ["conversation_id"], name: "index_support_chat_messages_on_conversation_id"
  end

  create_table "support_chat_settings", force: :cascade do |t|
    t.string "business_name"
    t.datetime "created_at", null: false
    t.boolean "enabled", default: true
    t.string "greeting_message", default: "Hi! How can we help you today?"
    t.string "primary_color", default: "#4F46E5"
    t.datetime "updated_at", null: false
    t.string "widget_position", default: "bottom-right"
    t.string "widget_token", null: false
    t.index ["widget_token"], name: "index_support_chat_settings_on_widget_token", unique: true
  end

  create_table "users", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "email", null: false
    t.string "role", default: "user"
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
  end

  add_foreign_key "support_chat_messages", "support_chat_conversations", column: "conversation_id"
end
