# frozen_string_literal: true

module SupportChat
  class Message < ApplicationRecord
    self.table_name = "support_chat_messages"

    belongs_to :conversation, class_name: "SupportChat::Conversation"

    validates :sender_type, presence: true, inclusion: { in: %w[guest agent] }
    validates :content, presence: true, length: { maximum: 5000 }
    validates :agent_id, presence: true, if: -> { sender_type == "agent" }

    after_create_commit :broadcast_to_channels
    after_create_commit :update_conversation_timestamp
    after_create_commit :schedule_email_notification

    scope :by_guest, -> { where(sender_type: "guest") }
    scope :by_agent, -> { where(sender_type: "agent") }
    scope :unread_by_agent, -> { where(sender_type: "guest", read_by_agent: false) }
    scope :unread_by_guest, -> { where(sender_type: "agent", read_by_guest: false) }

    def agent
      return nil unless agent_id

      SupportChat.configuration.user_class.constantize.find_by(id: agent_id)
    end

    private

    def broadcast_to_channels
      # Broadcast to guest's widget
      ActionCable.server.broadcast(
        "guest_#{conversation.session_token}",
        {
          id: id,
          content: content,
          sender_type: sender_type,
          created_at: created_at.iso8601
        }
      )

      # Broadcast to agents dashboard
      ActionCable.server.broadcast(
        "agents_dashboard",
        {
          conversation_id: conversation.id,
          message: {
            id: id,
            content: content,
            sender_type: sender_type,
            created_at: created_at.iso8601
          }
        }
      )
    end

    def update_conversation_timestamp
      conversation.update_column(:last_message_at, created_at)
    end

    def schedule_email_notification
      return unless sender_type == "agent"
      return unless SupportChat.configuration.email_notifications

      # Check if conversation is older than the notification delay
      delay_minutes = SupportChat.configuration.email_notification_delay
      return if conversation.created_at > delay_minutes.minutes.ago

      # Schedule email to be sent after 2 minutes of inactivity using ActiveJob
      SupportChat::NotificationMailer
        .agent_reply_notification(conversation.id)
        .deliver_later(wait: 2.minutes)
    end
  end
end
