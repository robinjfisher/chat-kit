# frozen_string_literal: true

module SupportChat
  class AgentChannel < SupportChat::ApplicationCable::Channel
    def subscribed
      # For now, allow all authenticated connections
      # TODO: Add proper authorization check
      stream_from "agents_dashboard"
    end

    def unsubscribed
      stop_all_streams
    end
  end
end
