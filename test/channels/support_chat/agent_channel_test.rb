# frozen_string_literal: true

require "test_helper"

module SupportChat
  class AgentChannelTest < ::ActionCable::Channel::TestCase
    setup do
      @admin_user = User.create!(email: "admin@example.com", role: "admin")
      @regular_user = User.create!(email: "user@example.com", role: "user")
    end

    test "subscribes successfully for support agents" do
      stub_connection(current_user: @admin_user)
      subscribe

      assert subscription.confirmed?
      assert_has_stream "agents_dashboard"
    end

    test "rejects subscription for non-support agents" do
      stub_connection(current_user: @regular_user)
      subscribe

      assert subscription.rejected?
    end

    test "rejects subscription without authentication" do
      stub_connection(current_user: nil)
      subscribe

      assert subscription.rejected?
    end

    test "unsubscribes and stops streams" do
      stub_connection(current_user: @admin_user)
      subscribe

      assert subscription.confirmed?

      unsubscribe

      assert_no_streams
    end

    private

    def stub_connection(stubs = {})
      # Create a mock connection with warden for authentication
      connection = super(stubs)

      # Mock the warden environment if current_user is provided
      if stubs[:current_user]
        warden = Object.new
        warden.define_singleton_method(:user) { stubs[:current_user] }

        env = { "warden" => warden }
        connection.define_singleton_method(:env) { env }
      end

      connection
    end
  end
end
