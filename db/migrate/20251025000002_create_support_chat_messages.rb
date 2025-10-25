# frozen_string_literal: true

class CreateSupportChatMessages < ActiveRecord::Migration[6.0]
  def change
    create_table :support_chat_messages do |t|
      t.references :conversation, null: false, foreign_key: { to_table: :support_chat_conversations }
      t.string :sender_type, null: false
      t.bigint :agent_id
      t.text :content, null: false
      t.boolean :read_by_guest, default: false
      t.boolean :read_by_agent, default: false

      t.timestamps
    end

    add_index :support_chat_messages, [:conversation_id, :created_at]
  end
end
