# frozen_string_literal: true

module SupportChat
  class Conversation < SupportChat::ApplicationRecord
    self.table_name = "support_chat_conversations"

    # Kaminari pagination configuration
    paginates_per 25

    has_many :messages, dependent: :destroy

    validates :guest_name, presence: true
    validates :guest_email, presence: true, format: { with: URI::MailTo::EMAIL_REGEXP }
    validates :session_token, presence: true, uniqueness: true
    validates :status, inclusion: { in: %w[open closed] }

    before_validation :generate_session_token, on: :create
    after_create :update_last_message_timestamp
    after_create_commit :broadcast_new_conversation
    after_create_commit :send_new_conversation_email

    scope :open, -> { where(status: "open") }
    scope :closed, -> { where(status: "closed") }
    scope :recent, -> { order(last_message_at: :desc) }

    def agent_unread_count
      messages.where(sender_type: "guest", read_by_agent: false).count
    end

    def guest_unread_count
      messages.where(sender_type: "agent", read_by_guest: false).count
    end

    def close!
      update!(status: "closed")
    end

    def signed_session_token
      Rails.application.message_verifier("support_chat_session").generate(session_token)
    end

    def self.find_by_signed_token(signed_token)
      session_token = Rails.application.message_verifier("support_chat_session").verify(signed_token)
      find_by(session_token: session_token)
    rescue ActiveSupport::MessageVerifier::InvalidSignature
      nil
    end

    private

    def generate_session_token
      self.session_token ||= SecureRandom.urlsafe_base64(32)
    end

    def update_last_message_timestamp
      update_column(:last_message_at, Time.current)
    end

    def broadcast_new_conversation
      # Broadcast new conversation to agents dashboard
      ActionCable.server.broadcast(
        "agents_dashboard",
        {
          type: "new_conversation",
          conversation: {
            id: id,
            guest_name: guest_name,
            guest_email: guest_email,
            created_at: created_at.iso8601,
            last_message_at: last_message_at.iso8601,
            status: status
          }
        }
      )
    end

    def send_new_conversation_email
      return unless SupportChat.configuration.new_conversation_email

      SupportChat::NotificationMailer
        .new_conversation_notification(id)
        .deliver_later
    end
  end
end
