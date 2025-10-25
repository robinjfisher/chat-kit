# frozen_string_literal: true

module SupportChat
  class WidgetController < ApplicationController
    skip_before_action :verify_authenticity_token
    before_action :verify_widget_token

    def config
      setting = Setting.current

      render json: {
        primary_color: setting.primary_color,
        greeting_message: setting.greeting_message,
        business_name: setting.business_name,
        enabled: setting.enabled
      }
    end

    def create_conversation
      conversation = Conversation.new(
        guest_name: params[:guest_name],
        guest_email: params[:guest_email],
        page_url: params[:page_url]
      )

      if conversation.save
        render json: {
          session_token: conversation.signed_session_token,
          conversation_id: conversation.id
        }, status: :created
      else
        render json: { errors: conversation.errors.full_messages }, status: :unprocessable_entity
      end
    end

    def create_message
      conversation = Conversation.find_by_signed_token(params[:session_token])

      return render json: { error: "Invalid session" }, status: :unauthorized unless conversation

      message = conversation.messages.new(
        content: params[:content],
        sender_type: "guest"
      )

      if message.save
        render json: { success: true, message_id: message.id }, status: :created
      else
        render json: { errors: message.errors.full_messages }, status: :unprocessable_entity
      end
    end

    def load_messages
      conversation = Conversation.find_by_signed_token(params[:session_token])

      return render json: { error: "Invalid session" }, status: :unauthorized unless conversation

      messages = conversation.messages.order(:created_at).map do |message|
        {
          id: message.id,
          content: message.content,
          sender_type: message.sender_type,
          created_at: message.created_at.iso8601
        }
      end

      render json: { messages: messages }
    end

    private

    def verify_widget_token
      token = request.headers["X-Widget-Token"] || params[:widget_token]
      setting = Setting.current

      return if token == setting.widget_token

      render json: { error: "Unauthorized" }, status: :unauthorized
    end
  end
end
