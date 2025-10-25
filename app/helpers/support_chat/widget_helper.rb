# frozen_string_literal: true

module SupportChat
  module WidgetHelper
    def chatkit_widget(options = {})
      setting = SupportChat::Setting.current

      config = {
        apiUrl: support_chat_engine_url.chomp("/"),
        widgetToken: setting.widget_token,
        primaryColor: options[:primary_color] || setting.primary_color,
        position: options[:position] || setting.widget_position,
        greetingMessage: options[:greeting_message] || setting.greeting_message,
        businessName: options[:business_name] || setting.business_name
      }

      # Load ActionCable from CDN since host app might not have it
      # Load widget assets using asset pipeline helpers
      html = <<~HTML
        <link rel="stylesheet" href="/assets/support_chat/widget.css" />
        <script src="https://cdn.jsdelivr.net/npm/@rails/actioncable@7.0/app/assets/javascripts/actioncable.js"></script>
        <script>
          window.__SupportChatConfig__ = #{config.to_json};
        </script>
        <script src="/assets/support_chat/widget.js"></script>
      HTML

      html.html_safe
    end

    private

    def support_chat_engine_url
      # Get the mounted engine URL
      SupportChat::Engine.routes.url_helpers.widget_config_path.split("/widget").first
    end
  end
end
