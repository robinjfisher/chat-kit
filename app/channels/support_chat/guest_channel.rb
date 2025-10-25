# frozen_string_literal: true

module SupportChat
  class GuestChannel < SupportChat::ApplicationCable::Channel
    def subscribed
      signed_token = params[:session_token]

      begin
        session_token = Rails.application.message_verifier("support_chat_session").verify(signed_token)
        conversation = Conversation.find_by(session_token: session_token)

        if conversation
          stream_from "guest_#{session_token}"
        else
          reject
        end
      rescue ActiveSupport::MessageVerifier::InvalidSignature
        reject
      end
    end

    def unsubscribed
      # Cleanup when channel is unsubscribed
      stop_all_streams
    end

    def mark_messages_read
      # Mark agent messages as read by guest
      signed_token = params[:session_token]
      session_token = Rails.application.message_verifier("support_chat_session").verify(signed_token)
      conversation = Conversation.find_by(session_token: session_token)

      if conversation
        conversation.messages.unread_by_guest.update_all(read_by_guest: true)
      end
    rescue ActiveSupport::MessageVerifier::InvalidSignature
      # Invalid token, do nothing
    end
  end
end
