# frozen_string_literal: true

SupportChat::Engine.routes.draw do
  # Widget API endpoints (public, token-authenticated)
  namespace :widget do
    get "config", to: "widget#config"
    post "conversations", to: "widget#create_conversation"
    post "messages", to: "widget#create_message"
    get "messages/:session_token", to: "widget#load_messages"
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
