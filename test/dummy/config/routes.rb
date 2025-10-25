Rails.application.routes.draw do
  mount SupportChat::Engine => "/support_chat"

  get "up" => "rails/health#show", as: :rails_health_check
end
