# frozen_string_literal: true

SupportChat.configure do |config|
  # REQUIRED: Specify your User model class (e.g., 'User', 'Admin', 'PowerUser')
  # This is the model that represents authenticated users in your application
  config.user_class = "User"

  # REQUIRED: Method to get the current user in controllers
  # This should match the method your application uses (e.g., :current_user, :current_admin)
  config.current_user_method = :current_user

  # OPTIONAL: Provide a proc to fetch the current user (advanced)
  # Use this if your authentication system isn't automatically detected
  # The proc receives the controller instance as an argument
  # Example:
  #   config.current_user_proc = ->(controller) { controller.send(:current_user) }
  # If not set, the gem will try to auto-detect from session (works with Devise, Authlogic, etc.)
  # config.current_user_proc = nil

  # REQUIRED: Method to check if a user is a support agent
  # You must implement this method on your user model
  # Example in app/models/user.rb:
  #   def support_agent?
  #     self.role == 'support' || self.admin?
  #   end
  config.support_agent_method = :support_agent?

  # OPTIONAL: Customize the mailer sender email
  config.mailer_sender = "support@example.com"

  # OPTIONAL: Enable or disable email notifications
  config.email_notifications = true

  # OPTIONAL: Time window (in minutes) to disable email notifications for new conversations
  # If a conversation is closed within this window, no email notifications are sent
  # This prevents spam for quick conversations
  config.email_notification_delay = 30
end
