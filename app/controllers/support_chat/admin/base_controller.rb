# frozen_string_literal: true

module SupportChat
  module Admin
    class BaseController < ActionController::Base
      # Protect from forgery - use null_session for API-style responses
      protect_from_forgery with: :exception, except: [:create]

      # Use the admin layout
      layout "support_chat/admin"

      before_action :authenticate_user!
      before_action :verify_support_agent!

      # Provide helper method access
      helper_method :current_user

      private

      def authenticate_user!
        unless current_user
          render json: { error: "Unauthorized" }, status: :unauthorized
        end
      end

      def verify_support_agent!
        support_agent_method = SupportChat.configuration.support_agent_method

        unless current_user&.send(support_agent_method)
          render json: { error: "Forbidden" }, status: :forbidden
        end
      end

      def current_user
        @current_user ||= fetch_user_from_host_app
      end

      def fetch_user_from_host_app
        # Prefer the configured proc if available
        if SupportChat.configuration.current_user_proc
          return SupportChat.configuration.current_user_proc.call(self)
        end

        # Fallback: Try to get user from session directly
        # This works with many common auth systems (Devise, Authlogic, etc.)
        user_class = SupportChat.configuration.user_class.constantize

        # Try common session keys
        user_id = session[:user_id] ||
                  session["user_id"] ||
                  session[:user_credentials] || # Authlogic
                  warden_user&.id # Devise

        return nil unless user_id
        user_class.find_by(id: user_id)
      end

      def warden_user
        # For Devise compatibility
        return nil unless respond_to?(:warden)
        warden.user
      end
    end
  end
end
