# frozen_string_literal: true

module SupportChat
  class Configuration
    attr_accessor :user_class,
                  :current_user_method,
                  :support_agent_method,
                  :mailer_sender,
                  :email_notifications,
                  :email_notification_delay

    def initialize
      @user_class = "User"
      @current_user_method = :current_user
      @support_agent_method = :support_agent?
      @mailer_sender = "support@example.com"
      @email_notifications = true
      @email_notification_delay = 30 # minutes
    end
  end

  class << self
    attr_writer :configuration

    def configuration
      @configuration ||= Configuration.new
    end

    def configure
      yield(configuration)
    end

    def reset_configuration!
      @configuration = Configuration.new
    end
  end
end
