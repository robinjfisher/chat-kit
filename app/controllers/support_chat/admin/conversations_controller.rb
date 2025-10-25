# frozen_string_literal: true

module SupportChat
  module Admin
    class ConversationsController < BaseController
      def index
        status_filter = params[:status] || "open"
        @conversations = Conversation.where(status: status_filter)
                                     .recent
                                     .page(params[:page])
                                     .per(25)

        # Mark messages as read by agent when viewing list
        unread_message_ids = @conversations.flat_map do |conv|
          conv.messages.unread_by_agent.pluck(:id)
        end

        Message.where(id: unread_message_ids).update_all(read_by_agent: true) if unread_message_ids.any?
      end

      def show
        @conversation = Conversation.find(params[:id])
        @messages = @conversation.messages.order(:created_at)

        # Mark all guest messages as read by agent
        @conversation.messages.unread_by_agent.update_all(read_by_agent: true)
      end

      def close
        @conversation = Conversation.find(params[:id])
        @conversation.close!

        redirect_to admin_conversation_path(@conversation), notice: "Conversation closed"
      end
    end
  end
end
