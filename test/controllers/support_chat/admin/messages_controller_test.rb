# frozen_string_literal: true

require "test_helper"

module SupportChat
  module Admin
    class MessagesControllerTest < ActionDispatch::IntegrationTest
      setup do
        @admin_user = User.create!(email: "admin@example.com", role: "admin")
        @conversation = Conversation.create!(
          guest_name: "John Doe",
          guest_email: "john@example.com"
        )
      end

      test "create sends message from agent" do
        sign_in_as(@admin_user)

        assert_difference "Message.count", 1 do
          post admin_conversation_messages_url(@conversation),
               params: { content: "How can I help you?" }
        end

        assert_response :created

        message = Message.last
        assert_equal "agent", message.sender_type
        assert_equal @admin_user.id, message.agent_id
        assert_equal "How can I help you?", message.content
      end

      test "create requires authentication" do
        post admin_conversation_messages_url(@conversation),
             params: { content: "Hello" }

        assert_response :unauthorized
      end

      test "create requires support agent permission" do
        regular_user = User.create!(email: "user@example.com", role: "user")
        sign_in_as(regular_user)

        post admin_conversation_messages_url(@conversation),
             params: { content: "Hello" }

        assert_response :forbidden
      end

      test "create requires content" do
        sign_in_as(@admin_user)

        post admin_conversation_messages_url(@conversation),
             params: {}

        assert_response :unprocessable_entity
      end

      test "create validates content length" do
        sign_in_as(@admin_user)

        post admin_conversation_messages_url(@conversation),
             params: { content: "a" * 5001 }

        assert_response :unprocessable_entity
      end

      private

      def admin_conversation_messages_url(conversation)
        "/support_chat/admin/conversations/#{conversation.id}/messages"
      end

      def sign_in_as(user)
        ApplicationController.class_eval do
          define_method(:current_user) { user }
        end
      end
    end
  end
end
