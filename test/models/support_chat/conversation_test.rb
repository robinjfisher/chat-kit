# frozen_string_literal: true

require "test_helper"

module SupportChat
  class ConversationTest < ActiveSupport::TestCase
    test "creates conversation with valid attributes" do
      conversation = Conversation.new(
        guest_name: "John Doe",
        guest_email: "john@example.com"
      )

      assert conversation.valid?
      assert conversation.save
      assert_not_nil conversation.session_token
      assert_equal "open", conversation.status
    end

    test "requires guest name" do
      conversation = Conversation.new(guest_email: "john@example.com")
      assert_not conversation.valid?
      assert_includes conversation.errors[:guest_name], "can't be blank"
    end

    test "requires guest email" do
      conversation = Conversation.new(guest_name: "John Doe")
      assert_not conversation.valid?
      assert_includes conversation.errors[:guest_email], "can't be blank"
    end

    test "requires valid email format" do
      conversation = Conversation.new(
        guest_name: "John Doe",
        guest_email: "invalid-email"
      )
      assert_not conversation.valid?
      assert_includes conversation.errors[:guest_email], "is invalid"
    end

    test "generates unique session token on create" do
      conv1 = Conversation.create!(guest_name: "John", guest_email: "john@example.com")
      conv2 = Conversation.create!(guest_name: "Jane", guest_email: "jane@example.com")

      assert_not_equal conv1.session_token, conv2.session_token
      assert conv1.session_token.length >= 32
      assert conv2.session_token.length >= 32
    end

    test "defaults to open status" do
      conversation = Conversation.create!(
        guest_name: "John",
        guest_email: "john@example.com"
      )

      assert_equal "open", conversation.status
    end

    test "validates status inclusion" do
      conversation = Conversation.new(
        guest_name: "John",
        guest_email: "john@example.com",
        status: "invalid"
      )

      assert_not conversation.valid?
      assert_includes conversation.errors[:status], "is not included in the list"
    end

    test "close! changes status to closed" do
      conversation = Conversation.create!(
        guest_name: "John",
        guest_email: "john@example.com"
      )

      conversation.close!
      assert_equal "closed", conversation.status
    end

    test "agent_unread_count returns count of unread guest messages" do
      conversation = Conversation.create!(
        guest_name: "John",
        guest_email: "john@example.com"
      )

      conversation.messages.create!(content: "Hello", sender_type: "guest", read_by_agent: false)
      conversation.messages.create!(content: "Anyone there?", sender_type: "guest", read_by_agent: false)
      conversation.messages.create!(content: "Hi", sender_type: "agent", agent_id: 1)

      assert_equal 2, conversation.agent_unread_count
    end

    test "signed_session_token generates verifiable token" do
      conversation = Conversation.create!(
        guest_name: "John",
        guest_email: "john@example.com"
      )

      signed_token = conversation.signed_session_token
      assert_not_nil signed_token

      found = Conversation.find_by_signed_token(signed_token)
      assert_equal conversation.id, found.id
    end

    test "find_by_signed_token returns nil for invalid token" do
      found = Conversation.find_by_signed_token("invalid_token")
      assert_nil found
    end

    test "scopes work correctly" do
      open1 = Conversation.create!(guest_name: "A", guest_email: "a@example.com", status: "open")
      closed1 = Conversation.create!(guest_name: "B", guest_email: "b@example.com", status: "closed")

      assert_includes Conversation.open, open1
      assert_not_includes Conversation.open, closed1
      assert_includes Conversation.closed, closed1
      assert_not_includes Conversation.closed, open1
    end
  end
end
