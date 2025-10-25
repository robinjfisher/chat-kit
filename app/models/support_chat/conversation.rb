# frozen_string_literal: true

module SupportChat
  class Conversation < ApplicationRecord
    self.table_name = "support_chat_conversations"

    has_many :messages, dependent: :destroy

    validates :guest_name, presence: true
    validates :guest_email, presence: true, format: { with: URI::MailTo::EMAIL_REGEXP }
    validates :session_token, presence: true, uniqueness: true
    validates :status, inclusion: { in: %w[open closed] }

    before_validation :generate_session_token, on: :create
    after_create :update_last_message_timestamp

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
  end
end
