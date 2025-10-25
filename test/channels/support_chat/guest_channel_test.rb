# frozen_string_literal: true

require "test_helper"

module SupportChat
  class GuestChannelTest < ::ActionCable::Channel::TestCase
    setup do
      @conversation = Conversation.create!(
        guest_name: "John Doe",
        guest_email: "john@example.com"
      )
      @signed_token = @conversation.signed_session_token
    end

    test "subscribes successfully with valid token" do
      subscribe(session_token: @signed_token)

      assert subscription.confirmed?
      assert_has_stream "guest_#{@conversation.session_token}"
    end

    test "rejects subscription with invalid token" do
      subscribe(session_token: "invalid_token")

      assert subscription.rejected?
    end

    test "rejects subscription without token" do
      subscribe

      assert subscription.rejected?
    end

    test "rejects subscription with token for non-existent conversation" do
      # Create a signed token for a session that doesn't exist
      fake_session = SecureRandom.urlsafe_base64(32)
      fake_signed = Rails.application.message_verifier("support_chat_session").generate(fake_session)

      subscribe(session_token: fake_signed)

      assert subscription.rejected?
    end

    test "unsubscribes and stops streams" do
      subscribe(session_token: @signed_token)
      assert subscription.confirmed?

      unsubscribe

      assert_no_streams
    end

    test "mark_messages_read updates guest message read status" do
      subscribe(session_token: @signed_token)

      message = @conversation.messages.create!(
        content: "Hello from agent",
        sender_type: "agent",
        agent_id: 1,
        read_by_guest: false
      )

      perform :mark_messages_read

      message.reload
      assert message.read_by_guest
    end

    test "mark_messages_read handles invalid token gracefully" do
      subscribe(session_token: @signed_token)

      # This should not raise an error
      assert_nothing_raised do
        # Manually call with bad token by stubbing params
        stub_connection(params: { session_token: "invalid" }) do
          perform :mark_messages_read
        end
      end
    end
  end
end
