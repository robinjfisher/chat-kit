# ChatKit

**Open-source customer support chat widget for Rails applications**

ChatKit is a Rails engine that provides embeddable customer support chat functionality with real-time messaging via ActionCable. It's a self-hosted alternative to expensive SaaS solutions like Intercom, Drift, and Crisp.

## Features

- 💬 **Real-time chat** - Instant messaging via ActionCable (WebSockets)
- 🎨 **Customizable widget** - Match your brand colors and positioning
- 👥 **Guest conversations** - No account required for website visitors
- 🔐 **Secure** - Signed session tokens, widget token authentication
- 📧 **Smart email notifications** - Batched notifications for longer conversations
- 🚀 **Easy installation** - Single command setup
- 📱 **Mobile responsive** - Works on all devices
- 🎯 **Rails-native** - Built specifically for Rails, no separate deployment needed

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'chatkit'
```

And then execute:

```bash
bundle install
```

Or install it yourself as:

```bash
gem install chatkit
```

## Quick Start

### 1. Run the installer

```bash
rails generate chatkit:install
rails db:migrate
```

This will:
- Copy migrations to your app
- Create `config/initializers/chatkit.rb`
- Mount the engine routes
- Display setup instructions

### 2. Configure your User model

Add a `support_agent?` method to your User model (or whatever model you specified in the initializer):

```ruby
# app/models/user.rb
class User < ApplicationRecord
  def support_agent?
    # Implement your logic here
    self.admin? || self.role == 'support'
  end
end
```

### 3. Add the widget to your layout

In `app/views/layouts/application.html.erb`, add before `</body>`:

```erb
<%= chatkit_widget %>
```

That's it! The chat widget is now live on your site.

## Configuration

Edit `config/initializers/chatkit.rb` to customize:

```ruby
SupportChat.configure do |config|
  # User model configuration
  config.user_class = "User"
  config.current_user_method = :current_user
  config.support_agent_method = :support_agent?

  # Email configuration
  config.mailer_sender = "support@yourdomain.com"
  config.email_notifications = true
  config.email_notification_delay = 30 # minutes
end
```

### Authentication Configuration

ChatKit attempts to auto-detect your authentication system (Devise, Authlogic, etc.) by checking common session keys. However, if you're using a custom authentication system or the auto-detection doesn't work, you can provide a `current_user_proc`:

```ruby
SupportChat.configure do |config|
  # ... other config ...

  # For Authlogic
  config.current_user_proc = lambda do |controller|
    user_session = UserSession.find
    user_session&.user
  end

  # For Devise (auto-detected, but can be explicit)
  config.current_user_proc = lambda do |controller|
    controller.current_user
  end

  # For custom authentication
  config.current_user_proc = lambda do |controller|
    # Your custom logic to fetch the current user
    # The proc receives the controller instance as an argument
    controller.send(:your_current_user_method)
  end
end
```

**When to use `current_user_proc`:**
- You're using Authlogic or another non-Devise authentication system
- Auto-detection fails in your application
- You have a custom authentication implementation
- You want explicit control over how the current user is fetched

## Widget Customization

You can customize the widget appearance when embedding it:

```erb
<%= chatkit_widget(
  primary_color: '#FF5733',
  position: 'bottom-left',
  greeting_message: 'Hello! How can we assist you?',
  business_name: 'Acme Support'
) %>
```

### Widget Options

- `primary_color` - Hex color for the widget (default: `#4F46E5`)
- `position` - Widget position: `bottom-right` or `bottom-left` (default: `bottom-right`)
- `greeting_message` - Welcome message shown to guests
- `business_name` - Your business name shown in widget header

## Admin Dashboard

Access the admin dashboard at `/support_chat/admin/conversations` (requires authentication as a support agent).

The dashboard allows you to:
- View all open and closed conversations
- See unread message counts
- Reply to guest messages in real-time
- Close conversations when resolved
- View guest information and conversation history

## How It Works

### For Guests
1. Guest clicks the chat bubble on your website
2. Provides their name and email
3. Starts chatting - messages are delivered instantly
4. Conversation persists across page loads via localStorage

### For Agents
1. Log in to your Rails app as a support agent
2. Visit `/support_chat/admin/conversations`
3. See all active conversations with unread indicators
4. Click a conversation to view history and reply
5. Messages are delivered to guests in real-time

### Email Notifications
- Conversations less than 30 minutes old: No emails (prevents spam for quick chats)
- Older conversations: Agent replies are batched and sent after 2 minutes of inactivity

## Technical Details

### Database Tables
- `support_chat_conversations` - Guest conversations with session tokens
- `support_chat_messages` - Individual messages (polymorphic sender)
- `support_chat_settings` - Widget configuration

### Security
- Session tokens are signed using `Rails.application.message_verifier`
- Widget API uses token authentication
- Admin dashboard requires user authentication
- All guest content is HTML-escaped to prevent XSS

### ActionCable Setup (Production)

**Redis is required for production** when running multiple Puma workers or web processes. Configure in `config/cable.yml`:

```yaml
production:
  adapter: redis
  url: <%= ENV.fetch("REDIS_URL") %>
  channel_prefix: your_app_production
```

**Why Redis is required:** The `async` adapter only works within a single process. With multiple Puma workers, messages broadcast in one worker won't reach WebSocket connections in other workers, causing messages to be randomly dropped. Redis enables message sharing across all processes.

**Note:** You can use the same Redis instance for both caching and ActionCable - no need for separate instances.

For development/test, the async adapter works fine (single process).

## Requirements

- Ruby >= 2.7.0
- Rails >= 6.0.0
- PostgreSQL, MySQL, or SQLite
- Kaminari >= 1.0.0 (for pagination - automatically installed as dependency)

## Development

After checking out the repo, run:

```bash
bundle install
rails test
```

## Roadmap

Future enhancements planned:
- File/image uploads
- Typing indicators
- Canned responses
- Conversation assignment
- Analytics dashboard
- Slack/Discord integrations

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/robinfisher/chatkit.

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Support

- Documentation: https://github.com/robinfisher/chatkit
- Issues: https://github.com/robinfisher/chatkit/issues

---

Made with ❤️ for the Rails community
