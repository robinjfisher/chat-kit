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
  end
end
