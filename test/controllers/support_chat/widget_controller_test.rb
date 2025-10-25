# frozen_string_literal: true

require "test_helper"

module SupportChat
  class WidgetControllerTest < ActionDispatch::IntegrationTest
    setup do
      @setting = Setting.current
      @widget_token = @setting.widget_token
    end

    # Config endpoint tests
    test "config returns widget configuration with valid token" do
      get widget_config_url, headers: { "X-Widget-Token" => @widget_token }

      assert_response :success
      json = JSON.parse(response.body)
      assert_equal @setting.primary_color, json["primary_color"]
      assert_equal @setting.greeting_message, json["greeting_message"]
      assert_equal @setting.enabled, json["enabled"]
    end

    test "config returns unauthorized without token" do
      get widget_config_url

      assert_response :unauthorized
      json = JSON.parse(response.body)
      assert_equal "Unauthorized", json["error"]
    end

    test "config returns unauthorized with invalid token" do
      get widget_config_url, headers: { "X-Widget-Token" => "invalid" }

      assert_response :unauthorized
    end

    # Create conversation tests
    test "create_conversation creates conversation with valid data" do
      assert_difference "Conversation.count", 1 do
        post widget_conversations_url,
             params: {
               guest_name: "John Doe",
               guest_email: "john@example.com",
               page_url: "https://example.com",
               widget_token: @widget_token
             },
             as: :json
      end

      assert_response :created
      json = JSON.parse(response.body)
      assert_not_nil json["session_token"]
      assert_not_nil json["conversation_id"]
    end

    test "create_conversation requires valid email" do
      post widget_conversations_url,
           params: {
             guest_name: "John Doe",
             guest_email: "invalid-email",
             widget_token: @widget_token
           },
           as: :json

      assert_response :unprocessable_entity
      json = JSON.parse(response.body)
      assert json["errors"].any?
    end

    test "create_conversation requires guest name" do
      post widget_conversations_url,
           params: {
             guest_email: "john@example.com",
             widget_token: @widget_token
           },
           as: :json

      assert_response :unprocessable_entity
    end

    test "create_conversation requires widget token" do
      post widget_conversations_url,
           params: {
             guest_name: "John",
             guest_email: "john@example.com"
           },
           as: :json

      assert_response :unauthorized
    end

    # Create message tests
    test "create_message creates message with valid session token" do
      conversation = Conversation.create!(
        guest_name: "John",
        guest_email: "john@example.com"
      )
      signed_token = conversation.signed_session_token

      assert_difference "Message.count", 1 do
        post widget_messages_url,
             params: {
               session_token: signed_token,
               content: "Hello, I need help",
               widget_token: @widget_token
             },
             as: :json
      end

      assert_response :created
      json = JSON.parse(response.body)
      assert_equal true, json["success"]
      assert_not_nil json["message_id"]
    end

    test "create_message requires valid session token" do
      post widget_messages_url,
           params: {
             session_token: "invalid",
             content: "Hello",
             widget_token: @widget_token
           },
           as: :json

      assert_response :unauthorized
      json = JSON.parse(response.body)
      assert_equal "Invalid session", json["error"]
    end

    test "create_message requires content" do
      conversation = Conversation.create!(
        guest_name: "John",
        guest_email: "john@example.com"
      )
      signed_token = conversation.signed_session_token

      post widget_messages_url,
           params: {
             session_token: signed_token,
             widget_token: @widget_token
           },
           as: :json

      assert_response :unprocessable_entity
    end

    # Load messages tests
    test "load_messages returns conversation history" do
      conversation = Conversation.create!(
        guest_name: "John",
        guest_email: "john@example.com"
      )
      conversation.messages.create!(content: "Hi", sender_type: "guest")
      conversation.messages.create!(content: "Hello", sender_type: "agent", agent_id: 1)

      signed_token = conversation.signed_session_token

      get widget_messages_url(signed_token),
          headers: { "X-Widget-Token" => @widget_token }

      assert_response :success
      json = JSON.parse(response.body)
      assert_equal 2, json["messages"].length
    end

    test "load_messages returns unauthorized with invalid token" do
      get widget_messages_url("invalid"),
          headers: { "X-Widget-Token" => @widget_token }

      assert_response :unauthorized
    end

    test "load_messages requires widget token" do
      conversation = Conversation.create!(
        guest_name: "John",
        guest_email: "john@example.com"
      )
      signed_token = conversation.signed_session_token

      get widget_messages_url(signed_token)

      assert_response :unauthorized
    end

    private

    def widget_config_url
      "/support_chat/widget/config"
    end

    def widget_conversations_url
      "/support_chat/widget/conversations"
    end

    def widget_messages_url(session_token = nil)
      if session_token
        "/support_chat/widget/messages/#{session_token}"
      else
        "/support_chat/widget/messages"
      end
    end
  end
end
