# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**ChatKit** is an open-source Ruby on Rails engine gem that provides embeddable customer support chat functionality. It's a self-hosted alternative to SaaS solutions like Intercom and Drift.

**Key characteristics:**
- Rails Engine gem (not a standalone Rails app)
- Real-time messaging via ActionCable (WebSockets)
- Embeddable JavaScript widget for website visitors
- Agent dashboard for support staff
- All data stored in host application's database
- Target: < 5 minute installation for Rails developers

## Architecture

### High-Level Structure

This is a **Rails Engine**, which means:
- It mounts into a host Rails application (not standalone)
- Has its own models, controllers, views, routes - but within `SupportChat::` namespace
- Database tables use `support_chat_` prefix to avoid conflicts
- Assets (JS/CSS) are served through the host app's asset pipeline

### Core Components

**1. Database Layer (3 tables)**
- `support_chat_conversations`: Guest conversations with session tokens for persistence
- `support_chat_messages`: Individual messages (polymorphic sender: guest or agent)
- `support_chat_settings`: Widget configuration (colors, tokens, greeting)

**2. Real-time Communication (ActionCable)**
- `SupportChat::GuestChannel`: Streams messages to individual guest widgets via session_token
- `SupportChat::AgentChannel`: Broadcasts all new messages to agent dashboard
- Message broadcasts happen in model callbacks (`after_create`)

**3. Public Widget API** (unauthenticated, token-verified)
- Routes under `/support_chat/widget`
- Authentication via `X-Widget-Token` header
- Endpoints: config, create conversation, send message, load history

**4. Agent Dashboard** (authenticated users only)
- Routes under `/support_chat/admin`
- Uses host app's authentication (`config.current_user_method`)
- Authorization via `config.support_agent_method`
- Built with Rails views + Hotwire/Turbo for real-time updates

**5. Widget (Vanilla JavaScript)**
- Single `widget.js` file with no dependencies
- Stores `session_token` in localStorage for conversation persistence
- Connects to WebSocket for real-time message delivery
- Embeds via script tag in host app's layout

### Key Design Decisions

- **Anonymous guests only** (MVP): No user accounts required for website visitors
- **Token-based guest auth**: Each conversation gets unique `session_token` for resuming
- **Host app controls agent permissions**: Gem doesn't define User model, uses host app's
- **Minimal UI dependencies**: No CSS frameworks, easy to override styles
- **Email notifications**: When agent replies and widget is closed, guest gets notified

## Development Commands

### Initial Gem Setup
```bash
# Create gem structure (if not already created)
bundle gem chatkit --test=minitest --mit

# Install dependencies
bundle install

# Run tests
rails test

# Lint code
bundle exec rubocop
```

### Testing Strategy

**Unit tests (RSpec):**
- Models: Validations, associations, callbacks, business logic
- Controllers: Authorization, token validation, response codes
- Channels: Subscription auth, broadcasting logic
- Mailers: Email content and delivery conditions

**Integration tests:**
- Full conversation flows (guest → agent → reply)
- WebSocket message delivery end-to-end

**System tests (Capybara):**
- Widget rendering and interaction
- Agent dashboard workflows

### Building and Testing the Gem Locally

```bash
# Build gem file
gem build chatkit.gemspec

# Install locally for testing
gem install ./chatkit-0.1.0.gem

# Or in a test Rails app's Gemfile:
gem 'chatkit', path: '/path/to/chatkit'
```

### Installation in Host App (Testing)

```bash
# In the host Rails app:
rails generate chatkit:install
rails db:migrate

# This should:
# - Copy migrations
# - Create config/initializers/chatkit.rb
# - Mount routes in config/routes.rb
# - Generate unique widget_token
```

## Critical Implementation Details

### Session Token Security
- **Signed tokens**: Use `Rails.application.message_verifier('support_chat_session')`
- Allows ActionCable channel authorization without database lookups
- No Redis dependency for token verification
- Never expose in logs or error messages
- Used for guest conversation persistence across browser sessions
- Stored in localStorage with `__sc_widget__` prefix

### Widget Token Security
- Generated once during installation
- Validates all public API requests
- Stored in `support_chat_settings` table
- Return 401 if missing/invalid

### ActionCable Production Requirements
For production deployments with multiple servers, host apps should configure Redis adapter:
```yaml
# config/cable.yml
production:
  adapter: redis
  url: <%= ENV.fetch("REDIS_URL") %>
```

**Note**: Redis is NOT required for the MVP. Async adapter works fine for single-server deployments. Session tokens are signed (not stored in Redis) for channel authorization.

### Message Broadcasting Pattern
```ruby
# In SupportChat::Message model
after_create_commit do
  # Broadcast to guest's widget
  ActionCable.server.broadcast(
    "guest_#{conversation.session_token}",
    message_data
  )

  # Broadcast to all agents
  ActionCable.server.broadcast(
    "agents_dashboard",
    message_data
  )
end
```

### N+1 Query Prevention
- Eager load messages when loading conversations: `includes(:messages)`
- Eager load conversation when loading messages: `includes(:conversation)`
- Add database indexes on: `session_token`, `status`, `last_message_at`, `conversation_id`

## Configuration API

Host apps configure via `config/initializers/support_chat.rb`:

```ruby
SupportChat.configure do |config|
  # REQUIRED: Host app's User model (could be User, Admin, PowerUser, etc.)
  config.user_class = 'User'

  # REQUIRED: Method to get current user
  config.current_user_method = :current_user

  # REQUIRED: Method to check support agent permission
  # Host app MUST implement this method on their user model
  config.support_agent_method = :support_agent?

  # OPTIONAL
  config.mailer_sender = 'support@example.com'
  config.email_notifications = true

  # OPTIONAL: Time window (in minutes) to disable email notifications for new conversations
  config.email_notification_delay = 30 # default
end
```

**Important**: The gem does NOT provide migrations for agent permissions. Host apps must implement the `support_agent?` method themselves:

```ruby
# In app/models/user.rb (or Admin, PowerUser, etc.)
class User < ApplicationRecord
  def support_agent?
    # Your implementation - could check a boolean column, role, etc.
    self.role == 'support' || self.admin?
  end
end
```

## File Structure Reference

```
chatkit/
├── app/
│   ├── models/support_chat/          # Conversation, Message, Setting
│   ├── controllers/support_chat/     # widget_controller, admin/*
│   ├── channels/support_chat/        # guest_channel, agent_channel
│   ├── mailers/support_chat/         # Email notifications
│   ├── views/support_chat/admin/     # Agent dashboard views
│   └── assets/
│       ├── javascripts/support_chat/widget.js
│       └── stylesheets/support_chat/
├── lib/
│   ├── support_chat.rb               # Main module, configuration
│   ├── support_chat/
│   │   ├── engine.rb                 # Rails::Engine definition
│   │   ├── version.rb
│   │   └── configuration.rb
│   └── generators/support_chat/install/
│       └── install_generator.rb      # rails g support_chat:install
├── db/migrate/                        # Three migration files
├── test/                              # Minitest tests
│   ├── dummy/                         # Dummy Rails app for integration tests
│   ├── models/
│   ├── controllers/
│   ├── channels/
│   └── integration/
└── chatkit.gemspec
```

## Widget Integration (In Host App)

Host app embeds widget using the view helper in `app/views/layouts/application.html.erb`:

```erb
<!-- Simple usage with defaults -->
<%= chatkit_widget %>

<!-- With custom options -->
<%= chatkit_widget(primary_color: '#FF5733', position: 'bottom-left') %>
```

**Widget Implementation Details**:
- Helper generates all necessary script tags and configuration
- Widget JavaScript uses `__sc_widget__` prefix for all localStorage keys
- Widget wrapped in IIFE with `window.SupportChatWidget` namespace
- Configuration object: `window.__SupportChatConfig__`

## Common Development Tasks

### Adding a New Model Attribute
1. Create migration in `db/migrate/`
2. Update model validations/associations
3. Add to controller strong params if needed
4. Update API response serialization
5. Write tests for new attribute

### Modifying Widget UI
- Edit `app/assets/javascripts/support_chat/widget.js`
- Edit `app/assets/stylesheets/support_chat/widget.css`
- Test in a host Rails app (can't run standalone)

### Adding New Configuration Option
1. Add to `lib/support_chat/configuration.rb`
2. Update generator template: `lib/generators/support_chat/install/templates/initializer.rb`
3. Document in README
4. Use via `SupportChat.configuration.your_option`

## Testing Workflow

```bash
# Run all tests
rails test

# Run specific test file
rails test test/models/support_chat/conversation_test.rb

# Run integration tests
rails test:integration

# Run linter
bundle exec rubocop

# Auto-fix linting issues
bundle exec rubocop -a
```

## Performance Considerations

### Database Indexes Required
- `conversations.session_token` (unique)
- `conversations.status`
- `conversations.last_message_at`
- `messages.conversation_id`
- Composite index: `(conversation_id, created_at)`

### Scaling ActionCable
- Use Redis adapter in production (not async/postgresql)
- Configure separate Redis instance for ActionCable if high traffic
- Monitor WebSocket connection count
- Consider separate server for ActionCable if > 1000 concurrent connections

### Widget Performance
- Keep `widget.js` < 50KB (no dependencies)
- Minimize DOM manipulation
- Debounce typing events if adding typing indicators
- Lazy-load conversation history (pagination)

## Key Implementation Decisions

### Email Notification Strategy
- **Conversations < 30 minutes old**: No email notifications sent
- **Conversations >= 30 minutes old**: Agent replies are batched
- **Batching logic**: Send email after 2 minutes of inactivity following last agent reply
- Prevents spam for quick conversations, batches longer support sessions

### Closed Conversation Behavior
When a guest messages a closed conversation, **create a new conversation** (don't reopen the old one). This provides:
- Clean separation between support sessions
- Better analytics on conversation resolution
- Simpler business logic

### Routes Mounting
The install generator **automatically modifies** `config/routes.rb` to add:
```ruby
mount SupportChat::Engine => "/support_chat"
```
This is standard practice for Rails engines and provides better DX.

### Settings Record Creation
The `SupportChat::Setting` record is created **during migration** via an `after_create` hook. The widget token is automatically generated at this time.

### View Helper
The widget is embedded using `<%= chatkit_widget %>` helper, which lives in `SupportChat::WidgetHelper`. This helper:
- Generates all necessary script tags
- Injects configuration from settings
- Supports optional parameter overrides
- Returns HTML-safe output

## Known Limitations (MVP)

- No file/image uploads
- No typing indicators
- No conversation assignment to specific agents
- No canned responses
- No analytics dashboard
- No Redis requirement (single-server deployments use async adapter)
- Guest conversation history tied to browser localStorage (cleared if user clears browser data)

## References

- Full PRD: `prd.md` (comprehensive requirements document)
- Rails Engines: https://guides.rubyonrails.org/engines.html
- ActionCable: https://guides.rubyonrails.org/action_cable_overview.html
- Gem development: https://guides.rubygems.org/make-your-own-gem/
