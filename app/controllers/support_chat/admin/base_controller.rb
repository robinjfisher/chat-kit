# frozen_string_literal: true

module SupportChat
  module Admin
    class BaseController < ApplicationController
      before_action :authenticate_user!
      before_action :verify_support_agent!

      private

      def authenticate_user!
        current_user_method = SupportChat.configuration.current_user_method

        unless respond_to?(current_user_method, true) && send(current_user_method)
          render json: { error: "Unauthorized" }, status: :unauthorized
        end
      end

      def verify_support_agent!
        current_user_method = SupportChat.configuration.current_user_method
        support_agent_method = SupportChat.configuration.support_agent_method
        user = send(current_user_method)

        unless user&.send(support_agent_method)
          render json: { error: "Forbidden" }, status: :forbidden
        end
      end

      def current_user
        send(SupportChat.configuration.current_user_method)
      end
    end
  end
end
