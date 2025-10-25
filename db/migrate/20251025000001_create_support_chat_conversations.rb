# frozen_string_literal: true

class CreateSupportChatConversations < ActiveRecord::Migration[6.0]
  def change
    create_table :support_chat_conversations do |t|
      t.string :guest_name, null: false
      t.string :guest_email, null: false
      t.string :session_token, null: false
      t.string :status, default: "open", null: false
      t.string :page_url
      t.datetime :last_message_at

      t.timestamps
    end

    add_index :support_chat_conversations, :session_token, unique: true
    add_index :support_chat_conversations, :status
    add_index :support_chat_conversations, :last_message_at
  end
end
