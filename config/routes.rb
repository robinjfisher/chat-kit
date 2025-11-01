# frozen_string_literal: true

SupportChat::Engine.routes.draw do
  # ActionCable endpoint for real-time messaging
  mount ActionCable.server => "/cable"

  # Widget API endpoints (public, token-authenticated)
  scope :widget, as: :widget do
    get "config", to: "widget#widget_config"
    post "conversations", to: "widget#create_conversation"
    post "messages", to: "widget#create_message"
    get "messages/:session_token", to: "widget#load_messages"
    post "conversations/close", to: "widget#close_conversation"
  end

  # Admin dashboard endpoints (user-authenticated)
  namespace :admin do
    resources :conversations, only: [:index, :show] do
      member do
        post :close
      end
      resources :messages, only: [:create]
    end
  end
end
