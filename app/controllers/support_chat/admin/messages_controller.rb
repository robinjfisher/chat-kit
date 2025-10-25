# frozen_string_literal: true

module SupportChat
  module Admin
    class MessagesController < BaseController
      skip_before_action :verify_authenticity_token

      def create
        @conversation = Conversation.find(params[:conversation_id])
        @message = @conversation.messages.new(
          content: params[:content],
          sender_type: "agent",
          agent_id: current_user.id
        )

        if @message.save
          redirect_to admin_conversation_path(@conversation), notice: "Message sent"
        else
          redirect_to admin_conversation_path(@conversation), alert: "Failed to send message"
        end
      end
    end
  end
end
