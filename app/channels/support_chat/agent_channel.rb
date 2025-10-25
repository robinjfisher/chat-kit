# frozen_string_literal: true

module SupportChat
  class AgentChannel < ApplicationCable::Channel
    def subscribed
      if authorized_agent?
        stream_from "agents_dashboard"
      else
        reject
      end
    end

    def unsubscribed
      stop_all_streams
    end

    private

    def authorized_agent?
      return false unless current_user

      support_agent_method = SupportChat.configuration.support_agent_method
      current_user.respond_to?(support_agent_method) && current_user.send(support_agent_method)
    end

    def current_user
      return nil unless connection.env["warden"]

      current_user_method = SupportChat.configuration.current_user_method
      connection.env["warden"].user
    end
  end
end
