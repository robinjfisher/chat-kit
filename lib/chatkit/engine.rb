# frozen_string_literal: true

module SupportChat
  class Engine < ::Rails::Engine
    isolate_namespace SupportChat

    config.generators do |g|
      g.test_framework :minitest
      g.fixture_replacement :minitest
    end

    initializer "support_chat.assets" do |app|
      app.config.assets.paths << root.join("app", "assets", "javascripts")
      app.config.assets.paths << root.join("app", "assets", "stylesheets")
      app.config.assets.precompile += %w[support_chat/widget.js support_chat/widget.css]
    end

    initializer "support_chat.helpers" do
      ActiveSupport.on_load(:action_view) do
        include SupportChat::WidgetHelper
      end
    end

    # Ensure Kaminari is loaded for pagination
    initializer "support_chat.kaminari" do
      require "kaminari"
    end

    # Configure ActionCable to use our connection class
    initializer "support_chat.action_cable" do
      config.to_prepare do
        # Set up ActionCable to use our isolated connection class
        ActionCable.server.config.connection_class = -> { SupportChat::ApplicationCable::Connection }
      end
    end
  end
end
