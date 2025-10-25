# frozen_string_literal: true

SupportChat.configure do |config|
  config.user_class = "User"
  config.current_user_method = :current_user
  config.support_agent_method = :support_agent?
  config.mailer_sender = "test@example.com"
  config.email_notifications = true
  config.email_notification_delay = 30
end
