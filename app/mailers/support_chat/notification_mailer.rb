# frozen_string_literal: true

module SupportChat
  class NotificationMailer < ApplicationMailer
    default from: -> { SupportChat.configuration.mailer_sender }

    def agent_reply_notification(conversation_id)
      @conversation = Conversation.find_by(id: conversation_id)

      return unless @conversation
      return unless SupportChat.configuration.email_notifications

      # Only send if conversation is older than the notification delay
      delay_minutes = SupportChat.configuration.email_notification_delay
      return if @conversation.created_at > delay_minutes.minutes.ago

      # Get all unread agent messages from the last few minutes
      @messages = @conversation.messages
                              .where(sender_type: "agent", read_by_guest: false)
                              .where("created_at > ?", 5.minutes.ago)
                              .order(:created_at)

      return if @messages.empty?

      mail(
        to: @conversation.guest_email,
        subject: "New reply from #{setting.business_name || 'Support'}"
      )

      # Mark messages as having email sent
      @messages.update_all(read_by_guest: true)
    end

    private

    def setting
      @setting ||= Setting.current
    end
  end
end
