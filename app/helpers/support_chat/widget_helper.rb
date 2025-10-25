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

      html = <<~HTML
        <script>
          window.__SupportChatConfig__ = #{config.to_json};
        </script>
        #{javascript_include_tag "support_chat/widget"}
        #{stylesheet_link_tag "support_chat/widget"}
      HTML

      html.html_safe
    end

    private

    def support_chat_engine_url
      # Get the mounted engine URL
      main_app.url_for(controller: "support_chat/widget", action: "config", only_path: true)
              .split("/widget").first
    end
  end
end
