# frozen_string_literal: true

require "test_helper"

module SupportChat
  module Admin
    class ConversationsControllerTest < ActionDispatch::IntegrationTest
      setup do
        @admin_user = User.create!(email: "admin@example.com", role: "admin")
        @regular_user = User.create!(email: "user@example.com", role: "user")

        @conversation = Conversation.create!(
          guest_name: "John Doe",
          guest_email: "john@example.com"
        )
        @conversation.messages.create!(
          content: "Hello",
          sender_type: "guest"
        )
      end

      # Authentication tests
      test "index requires authentication" do
        get admin_conversations_url

        assert_response :unauthorized
      end

      test "index requires support agent permission" do
        sign_in_as(@regular_user)
        get admin_conversations_url

        assert_response :forbidden
      end

      test "index works for support agents" do
        sign_in_as(@admin_user)
        get admin_conversations_url

        assert_response :success
      end

      # Index tests
      test "index shows open conversations by default" do
        sign_in_as(@admin_user)

        open_conv = Conversation.create!(
          guest_name: "Open User",
          guest_email: "open@example.com",
          status: "open"
        )
        closed_conv = Conversation.create!(
          guest_name: "Closed User",
          guest_email: "closed@example.com",
          status: "closed"
        )

        get admin_conversations_url

        assert_response :success
        assert_select ".conversation-item", minimum: 1
      end

      test "index filters by status parameter" do
        sign_in_as(@admin_user)

        get admin_conversations_url(status: "closed")

        assert_response :success
      end

      test "index marks unread messages as read" do
        sign_in_as(@admin_user)

        message = @conversation.messages.create!(
          content: "Unread message",
          sender_type: "guest",
          read_by_agent: false
        )

        get admin_conversations_url

        message.reload
        assert message.read_by_agent
      end

      # Show tests
      test "show displays conversation details" do
        sign_in_as(@admin_user)

        get admin_conversation_url(@conversation)

        assert_response :success
        assert_select ".conversation-detail"
        assert_select ".message", minimum: 1
      end

      test "show marks guest messages as read" do
        sign_in_as(@admin_user)

        unread_message = @conversation.messages.create!(
          content: "Unread",
          sender_type: "guest",
          read_by_agent: false
        )

        get admin_conversation_url(@conversation)

        unread_message.reload
        assert unread_message.read_by_agent
      end

      test "show requires authentication" do
        get admin_conversation_url(@conversation)

        assert_response :unauthorized
      end

      # Close tests
      test "close changes conversation status" do
        sign_in_as(@admin_user)

        post close_admin_conversation_url(@conversation)

        @conversation.reload
        assert_equal "closed", @conversation.status
        assert_redirected_to admin_conversation_path(@conversation)
      end

      test "close requires authentication" do
        post close_admin_conversation_url(@conversation)

        assert_response :unauthorized
      end

      private

      def admin_conversations_url(params = {})
        "/support_chat/admin/conversations" + (params.any? ? "?#{params.to_query}" : "")
      end

      def admin_conversation_url(conversation)
        "/support_chat/admin/conversations/#{conversation.id}"
      end

      def close_admin_conversation_url(conversation)
        "/support_chat/admin/conversations/#{conversation.id}/close"
      end

      def sign_in_as(user)
        # Mock authentication - in real app would use session/devise/etc
        # For testing, we'll stub the current_user method
        ApplicationController.class_eval do
          define_method(:current_user) { user }
        end
      end
    end
  end
end
