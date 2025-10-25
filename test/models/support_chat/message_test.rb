# frozen_string_literal: true

require "test_helper"

module SupportChat
  class MessageTest < ActiveSupport::TestCase
    setup do
      @conversation = Conversation.create!(
        guest_name: "John Doe",
        guest_email: "john@example.com"
      )
    end

    test "creates guest message with valid attributes" do
      message = @conversation.messages.new(
        content: "Hello, I need help",
        sender_type: "guest"
      )

      assert message.valid?
      assert message.save
    end

    test "creates agent message with valid attributes" do
      message = @conversation.messages.new(
        content: "How can I help you?",
        sender_type: "agent",
        agent_id: 1
      )

      assert message.valid?
      assert message.save
    end

    test "requires content" do
      message = @conversation.messages.new(sender_type: "guest")

      assert_not message.valid?
      assert_includes message.errors[:content], "can't be blank"
    end

    test "requires sender_type" do
      message = @conversation.messages.new(content: "Hello")

      assert_not message.valid?
      assert_includes message.errors[:sender_type], "can't be blank"
    end

    test "validates sender_type inclusion" do
      message = @conversation.messages.new(
        content: "Hello",
        sender_type: "invalid"
      )

      assert_not message.valid?
      assert_includes message.errors[:sender_type], "is not included in the list"
    end

    test "requires agent_id for agent messages" do
      message = @conversation.messages.new(
        content: "Hello",
        sender_type: "agent"
      )

      assert_not message.valid?
      assert_includes message.errors[:agent_id], "can't be blank"
    end

    test "validates content length" do
      message = @conversation.messages.new(
        content: "a" * 5001,
        sender_type: "guest"
      )

      assert_not message.valid?
      assert_includes message.errors[:content], "is too long (maximum is 5000 characters)"
    end

    test "defaults read flags to false" do
      message = @conversation.messages.create!(
        content: "Hello",
        sender_type: "guest"
      )

      assert_equal false, message.read_by_agent
      assert_equal false, message.read_by_guest
    end

    test "scopes work correctly" do
      guest_msg = @conversation.messages.create!(content: "Hi", sender_type: "guest")
      agent_msg = @conversation.messages.create!(content: "Hello", sender_type: "agent", agent_id: 1)

      assert_includes Message.by_guest, guest_msg
      assert_not_includes Message.by_guest, agent_msg
      assert_includes Message.by_agent, agent_msg
      assert_not_includes Message.by_agent, guest_msg
    end

    test "unread scopes work correctly" do
      unread_guest = @conversation.messages.create!(
        content: "Hi",
        sender_type: "guest",
        read_by_agent: false
      )

      read_guest = @conversation.messages.create!(
        content: "Hello",
        sender_type: "guest",
        read_by_agent: true
      )

      assert_includes Message.unread_by_agent, unread_guest
      assert_not_includes Message.unread_by_agent, read_guest
    end

    test "updates conversation last_message_at on create" do
      time_before = @conversation.last_message_at

      sleep 0.1

      @conversation.messages.create!(
        content: "Hello",
        sender_type: "guest"
      )

      @conversation.reload
      assert_not_equal time_before, @conversation.last_message_at
    end
  end
end
