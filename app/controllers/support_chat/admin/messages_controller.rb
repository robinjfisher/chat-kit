# frozen_string_literal: true

module SupportChat
  module Admin
    class MessagesController < BaseController
      def create
        @conversation = Conversation.find(params[:conversation_id])
        @message = @conversation.messages.new(
          content: params[:content],
          sender_type: "agent",
          agent_id: current_user.id
        )

        if @message.save
          head :created
        else
          render json: { errors: @message.errors.full_messages }, status: :unprocessable_entity
        end
      end
    end
  end
end
