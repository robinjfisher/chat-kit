# frozen_string_literal: true

class CreateSupportChatSettings < ActiveRecord::Migration[6.0]
  def change
    create_table :support_chat_settings do |t|
      t.string :widget_token, null: false
      t.string :primary_color, default: "#4F46E5"
      t.string :widget_position, default: "bottom-right"
      t.string :greeting_message, default: "Hi! How can we help you today?"
      t.string :business_name
      t.boolean :enabled, default: true

      t.timestamps
    end

    add_index :support_chat_settings, :widget_token, unique: true

    # Create initial settings record
    reversible do |dir|
      dir.up do
        SupportChat::Setting.create!(
          widget_token: SecureRandom.urlsafe_base64(32)
        )
      end
    end
  end
end
