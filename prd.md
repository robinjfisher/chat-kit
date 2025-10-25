# Product Requirements Document (PRD)
## ChatKit - Open Source Customer Support Widget for Rails

**Version:** 1.0 MVP  
**Last Updated:** October 25, 2025  
**Status:** Ready for Development  
**Target Launch:** 4 weeks from start

---

## 1. Executive Summary

### 1.1 Overview
ChatKit is an open-source Ruby on Rails gem that provides lightweight, embeddable customer support chat functionality. It allows website visitors to initiate conversations with support agents in real-time, offering a self-hosted alternative to expensive SaaS solutions like Intercom, Drift, and Crisp.

### 1.2 Problem Statement
Small businesses and startups face prohibitively expensive customer support chat solutions ($39-$2,500+/month). Existing open-source alternatives like Chatwoot require separate deployment and complex setup. There is no simple Rails-native solution that can be embedded directly into an existing Rails application.

### 1.3 Solution
A Rails engine gem that:
- Installs with a single command
- Runs within the existing Rails application (no separate deployment)
- Provides an embeddable JavaScript widget for website visitors
- Includes an agent dashboard for support staff
- Uses ActionCable for real-time messaging
- Stores all data in the host application's database

### 1.4 Success Metrics
- Installation completed in < 5 minutes
- Widget loads in < 500ms
- Messages delivered in < 1 second
- 100% uptime during normal Rails application operation
- Dogfooded on creator's SaaS within 4 weeks

---

## 2. Target Audience

### 2.1 Primary Users
- **Rails developers** building SaaS applications
- **Bootstrapped startups** needing cost-effective support chat
- **Privacy-conscious companies** wanting self-hosted solutions
- **Small businesses** (1-10 employees) with existing Rails apps

### 2.2 User Personas

**Persona 1: Sarah - Solo Founder**
- Runs a Rails SaaS with 100 customers
- Handles support herself
- Budget: $0-50/month for tools
- Needs: Simple, reliable, immediate setup

**Persona 2: Dev Team at 10-person Startup**
- 3 support agents
- Developer can customize/extend
- Budget: $0-200/month
- Needs: Self-hosted, customizable, scales to 1000s of conversations

---

## 3. MVP Scope

### 3.1 In Scope (Must Have)

#### 3.1.1 Guest Chat Widget
- **Anonymous chat initiation** - No user account required
- **Guest information collection** - Name and email capture before chat
- **Real-time messaging** - Instant message delivery via WebSockets
- **Conversation persistence** - Session token in localStorage to resume chats
- **Embeddable on any page** - Single script tag integration
- **Visual customization** - Primary color and position configuration
- **Mobile responsive** - Works on phones and tablets

#### 3.1.2 Agent Dashboard
- **Conversation list view** - See all open conversations ordered by most recent
- **Individual conversation view** - Read full message history
- **Real-time message notifications** - Instant updates when guests message
- **Reply functionality** - Send messages to guests in real-time
- **Close conversations** - Mark conversations as resolved
- **Unread message indicators** - Count of unread messages per conversation

#### 3.1.3 Backend Infrastructure
- **Database schema** - Conversations, Messages, Settings tables
- **REST API endpoints** - For widget to communicate with backend
- **ActionCable channels** - Separate channels for guests and agents
- **Email notifications** - Notify guests when agents reply (if widget closed)
- **Authentication** - Widget token verification for public API
- **Agent authorization** - Ensure only authorized users access dashboard

#### 3.1.4 Installation & Configuration
- **Rails generator** - `rails generate support_chat:install`
- **Automatic migrations** - Database tables created automatically
- **Initializer file** - Configuration options in `config/initializers/`
- **Route mounting** - Automatically mount engine routes
- **Widget token generation** - Unique token created on first install

#### 3.1.5 Documentation
- **README with quick start** - 5-minute setup guide
- **Installation instructions** - Step-by-step with code examples
- **Configuration options** - Document all customization settings
- **Deployment guide** - ActionCable/Redis setup for production
- **Troubleshooting section** - Common issues and solutions

### 3.2 Out of Scope (Future Versions)

The following features are explicitly **not** included in the MVP:
- ❌ File/image uploads
- ❌ Typing indicators
- ❌ Conversation assignment to specific agents
- ❌ Canned/saved responses
- ❌ Agent notes (internal comments)
- ❌ Conversation tags/categories
- ❌ Analytics dashboard
- ❌ Conversation search
- ❌ Offline message queue (when no agents available)
- ❌ Guest conversation history across sessions
- ❌ Multi-language support
- ❌ Browser notifications
- ❌ Mobile apps
- ❌ Integration with Slack/Discord/Email
- ❌ Custom fields in guest form
- ❌ Automatic conversation routing
- ❌ Business hours settings
- ❌ Agent online/offline status
- ❌ Multiple widget instances per site

---

## 4. Technical Specifications

### 4.1 Technology Stack
- **Backend**: Ruby on Rails 6.0+ (Rails Engine)
- **Database**: PostgreSQL, MySQL, SQLite (database-agnostic migrations)
- **Real-time**: ActionCable (WebSockets, no Redis dependency for MVP)
- **Frontend (Widget)**: Vanilla JavaScript (no dependencies)
- **Frontend (Dashboard)**: Rails views with Hotwire/Turbo
- **Styling**: Minimal inline CSS (easily overridable)
- **Testing**: Minitest with dummy Rails app in spec/dummy/

### 4.2 Database Schema

#### 4.2.1 support_chat_conversations
```ruby
{
  id: integer (primary key),
  guest_name: string (not null),
  guest_email: string (not null),
  session_token: string (not null, unique, indexed),
  status: string (default: 'open', indexed) # 'open' or 'closed',
  page_url: string, # URL where chat was initiated
  last_message_at: datetime (indexed),
  created_at: datetime,
  updated_at: datetime
}
```

#### 4.2.2 support_chat_messages
```ruby
{
  id: integer (primary key),
  conversation_id: integer (foreign key, not null, indexed),
  sender_type: string (not null), # 'guest' or 'agent'
  agent_id: integer (foreign key to users, nullable),
  content: text (not null),
  read_by_guest: boolean (default: false),
  read_by_agent: boolean (default: false),
  created_at: datetime (indexed with conversation_id),
  updated_at: datetime
}
```

#### 4.2.3 support_chat_settings
```ruby
{
  id: integer (primary key),
  widget_token: string (not null, unique, indexed),
  primary_color: string (default: '#4F46E5'),
  widget_position: string (default: 'bottom-right'), # 'bottom-right' or 'bottom-left'
  greeting_message: string (default: 'Hi! How can we help you today?'),
  business_name: string,
  enabled: boolean (default: true),
  created_at: datetime,
  updated_at: datetime
}
```

### 4.3 API Endpoints

#### 4.3.1 Public Widget API (No authentication required, uses widget token)

**Base URL**: `/support_chat/widget`

| Endpoint | Method | Purpose | Request Body | Response |
|----------|--------|---------|--------------|----------|
| `/config` | GET | Get widget configuration | widget_token | `{primary_color, greeting_message, business_name}` |
| `/conversations` | POST | Create new conversation | `{guest_name, guest_email, page_url, widget_token}` | `{session_token, conversation_id}` |
| `/messages` | POST | Send message from guest | `{session_token, content, widget_token}` | `{success: true, message_id}` |
| `/messages/:session_token` | GET | Load conversation history | widget_token | `{messages: [{id, content, sender_type, created_at}]}` |

**Authentication**: All requests must include `X-Widget-Token` header or `widget_token` parameter

#### 4.3.2 Agent Dashboard API (Requires user authentication)

**Base URL**: `/support_chat/admin`

| Endpoint | Method | Purpose | Authentication |
|----------|--------|---------|----------------|
| `/conversations` | GET | List all conversations | Required |
| `/conversations/:id` | GET | View single conversation | Required |
| `/conversations/:id/close` | POST | Close conversation | Required |
| `/conversations/:id/messages` | POST | Send message as agent | Required |

### 4.4 ActionCable Channels

#### 4.4.1 SupportChat::GuestChannel
- **Purpose**: Stream messages to individual guest widgets
- **Subscription parameter**: `session_token`
- **Authorization**: Verify signed session_token (no database lookup required)
- **Stream name**: `guest_#{session_token}`
- **Broadcasts**: New messages from agents

**Implementation Note**: Session tokens are signed using `Rails.application.message_verifier` to avoid database queries on every ActionCable subscription. This eliminates Redis dependency for token verification.

#### 4.4.2 SupportChat::AgentChannel
- **Purpose**: Stream all new messages to agent dashboard
- **Subscription parameter**: None (user-based)
- **Authorization**: Verify current_user is support agent
- **Stream name**: `agents_dashboard`
- **Broadcasts**: All new messages from guests, conversation updates

### 4.5 File Structure

```
chatkit/
├── app/
│   ├── models/
│   │   └── support_chat/
│   │       ├── conversation.rb
│   │       ├── message.rb
│   │       └── setting.rb
│   ├── controllers/
│   │   └── support_chat/
│   │       ├── widget_controller.rb
│   │       └── admin/
│   │           ├── conversations_controller.rb
│   │           └── messages_controller.rb
│   ├── channels/
│   │   └── support_chat/
│   │       ├── guest_channel.rb
│   │       └── agent_channel.rb
│   ├── mailers/
│   │   └── support_chat/
│   │       └── notification_mailer.rb
│   ├── views/
│   │   └── support_chat/
│   │       ├── admin/
│   │       │   ├── conversations/
│   │       │   │   ├── index.html.erb
│   │       │   │   └── show.html.erb
│   │       │   └── messages/
│   │       │       └── _message.html.erb
│   │       └── notification_mailer/
│   │           └── new_agent_reply.html.erb
│   └── assets/
│       ├── javascripts/
│       │   └── support_chat/
│       │       ├── widget.js
│       │       └── admin.js
│       └── stylesheets/
│           └── support_chat/
│               ├── widget.css
│               └── admin.css
├── config/
│   └── routes.rb
├── db/
│   └── migrate/
│       ├── 20251025000001_create_support_chat_conversations.rb
│       ├── 20251025000002_create_support_chat_messages.rb
│       └── 20251025000003_create_support_chat_settings.rb
├── lib/
│   ├── support_chat.rb
│   ├── support_chat/
│   │   ├── version.rb
│   │   ├── engine.rb
│   │   └── configuration.rb
│   ├── generators/
│   │   └── support_chat/
│   │       └── install/
│   │           ├── install_generator.rb
│   │           └── templates/
│   │               └── initializer.rb
│   └── tasks/
│       └── support_chat_tasks.rake
├── test/
│   ├── dummy/                         # Dummy Rails app for testing
│   ├── models/
│   ├── controllers/
│   ├── channels/
│   └── integration/
├── chatkit.gemspec
├── Gemfile
├── Rakefile
├── LICENSE (MIT)
└── README.md
```

### 4.6 Configuration Options

Host application can configure via `config/initializers/support_chat.rb`:

```ruby
SupportChat.configure do |config|
  # Required: Specify the User model class (could be User, Admin, PowerUser, etc.)
  config.user_class = 'User'

  # Required: Method to get current user in controllers
  config.current_user_method = :current_user

  # Required: Method to check if user is support agent
  # Host app must implement this method on their user model
  config.support_agent_method = :support_agent?

  # Optional: Customize mailer sender
  config.mailer_sender = 'support@example.com'

  # Optional: Enable/disable email notifications
  config.email_notifications = true

  # Optional: Time window (in minutes) to disable email notifications for new conversations
  # If a conversation is closed within this window, no email notifications are sent
  config.email_notification_delay = 30
end
```

**Note on Agent Authorization:**
The gem does not provide a migration for agent permissions. Host applications must implement the `support_agent?` method on their configured user model. Example:

```ruby
# In app/models/user.rb (or Admin, PowerUser, etc.)
class User < ApplicationRecord
  def support_agent?
    # Your implementation - could check a boolean column, role, etc.
    self.role == 'support' || self.admin?
  end
end
```

### 4.7 Widget Integration

Host application embeds widget using the view helper:

```erb
<!-- In app/views/layouts/application.html.erb (before </body>) -->
<%= support_chat_widget %>
```

The helper accepts optional parameters to override settings:

```erb
<%= support_chat_widget(primary_color: '#FF5733', position: 'bottom-left') %>
```

**Widget Implementation Details:**
- Helper generates all necessary script tags and configuration
- Widget JavaScript uses `__sc_widget__` prefix for all localStorage keys to avoid collisions
- Widget JavaScript wrapped in IIFE with `window.SupportChatWidget` namespace
- Configuration object: `window.__SupportChatConfig__`

---

## 5. User Workflows

### 5.1 Guest Initiates Conversation

```
1. Guest visits website with widget installed
2. Widget bubble appears in bottom-right corner
3. Guest clicks bubble → modal opens
4. Guest sees greeting message
5. Guest enters name and email
6. Guest clicks "Start Chat"
7. API creates conversation, returns signed session_token
8. Widget stores session_token in localStorage as __sc_widget__session_token
9. Widget subscribes to GuestChannel
10. Guest sees chat interface, can send messages
```

### 5.2 Guest Sends Message

```
1. Guest types message and clicks Send
2. Widget POSTs to /widget/messages
3. Backend creates Message record with sender_type='guest'
4. Message.after_create broadcasts to:
   - guest_{session_token} channel (confirmation)
   - agents_dashboard channel (notify all agents)
5. Guest sees message appear immediately
6. All online agents see new message notification
```

### 5.3 Agent Responds to Conversation

```
1. Agent is logged into dashboard at /support_chat/admin/conversations
2. Agent sees list of open conversations
3. New message appears with unread indicator
4. Agent clicks conversation
5. Agent sees full message history
6. Unread messages marked as read_by_agent=true
7. Agent types response and clicks Send
8. Backend creates Message record with sender_type='agent'
9. Message.after_create broadcasts to guest_{session_token}
10. Guest's widget immediately shows agent response
11. Email notification logic:
    - If conversation created_at < 30 minutes ago: no email sent
    - If conversation created_at >= 30 minutes ago: agent replies are batched
    - Email sent after last agent reply + 2 minutes of inactivity
```

### 5.4 Guest Returns to Website (Resuming Conversation)

```
1. Guest visits website again (hours/days later)
2. Widget loads, finds session_token in localStorage (__sc_widget__session_token)
3. Widget calls GET /widget/messages/:session_token
4. Backend returns message history
5. Widget displays conversation history
6. Guest can continue conversation
```

### 5.5 Agent Closes Conversation

```
1. Agent viewing conversation in dashboard
2. Agent clicks "Close Conversation" button
3. Backend updates conversation.status = 'closed'
4. Conversation moves to "Closed" tab in dashboard
5. If guest sends a new message to closed conversation, a new conversation is created
```

---

## 6. Functional Requirements

### 6.1 Widget Requirements

| ID | Requirement | Priority | Acceptance Criteria |
|----|-------------|----------|---------------------|
| W-1 | Widget bubble visible on page load | Must Have | Bubble appears within 500ms, positioned correctly |
| W-2 | Guest can open chat modal | Must Have | Click bubble → modal opens with animation |
| W-3 | Guest provides name/email before chatting | Must Have | Form validation, required fields enforced |
| W-4 | Guest can send text messages | Must Have | Messages appear instantly, character limit 5000 |
| W-5 | Guest receives agent replies in real-time | Must Have | Messages appear within 1 second |
| W-6 | Widget persists conversation across page loads | Must Have | session_token in localStorage, conversation resumes |
| W-7 | Widget works on mobile devices | Must Have | Responsive design, touch-friendly, fullscreen on mobile |
| W-8 | Widget color customizable | Must Have | Primary color configurable, applied to bubble and header |
| W-9 | Widget position customizable | Must Have | bottom-right or bottom-left placement |
| W-10 | Widget can be closed and reopened | Must Have | Close button, reopens to same conversation |

### 6.2 Agent Dashboard Requirements

| ID | Requirement | Priority | Acceptance Criteria |
|----|-------------|----------|---------------------|
| D-1 | List all conversations | Must Have | Paginated list, ordered by last_message_at DESC |
| D-2 | Show unread message count per conversation | Must Have | Badge with count, updates in real-time |
| D-3 | View full conversation history | Must Have | All messages displayed, guest info visible |
| D-4 | Agent can send replies | Must Have | Text input, messages sent instantly |
| D-5 | Real-time updates when guests message | Must Have | New messages appear without refresh |
| D-6 | Agent can close conversations | Must Have | "Close" button, moves to closed tab |
| D-7 | Distinguish between open and closed conversations | Must Have | Tabs or filter: Open (default) / Closed |
| D-8 | Show guest information | Must Have | Display name, email, page URL |
| D-9 | Mark messages as read | Must Have | Automatically mark as read when agent views |
| D-10 | Only authorized users can access | Must Have | Authentication required, 403 for non-agents |

### 6.3 Backend Requirements

| ID | Requirement | Priority | Acceptance Criteria |
|----|-------------|----------|---------------------|
| B-1 | Generate unique signed session tokens | Must Have | Using Rails.application.message_verifier, URL-safe |
| B-2 | Validate widget token on all public API calls | Must Have | 401 response if invalid/missing token |
| B-3 | Broadcast messages via ActionCable | Must Have | Both guest and agent channels receive updates |
| B-4 | Store all messages persistently | Must Have | Database-agnostic storage, no message loss |
| B-5 | Update conversation.last_message_at on new messages | Must Have | Enables proper sorting in dashboard |
| B-6 | Batch email notifications with time-based logic | Must Have | No emails for conversations < 30 min old, batch replies |
| B-7 | Prevent unauthorized access to conversations | Must Have | Guests only access via signed token, agents via auth |
| B-8 | Handle concurrent messages gracefully | Must Have | No race conditions, messages in correct order |
| B-9 | Support multiple simultaneous conversations | Must Have | 100+ concurrent conversations with no performance issues |
| B-10 | Create new conversation when guest messages closed conversation | Must Have | Seamless experience for guests |

### 6.4 Installation Requirements

| ID | Requirement | Priority | Acceptance Criteria |
|----|-------------|----------|---------------------|
| I-1 | One-command installation | Must Have | `rails generate chatkit:install` completes setup |
| I-2 | Automatic database migrations | Must Have | Migrations copied and can be run immediately |
| I-3 | Generate initializer with config options | Must Have | `config/initializers/chatkit.rb` created |
| I-4 | Mount routes automatically | Must Have | Generator modifies routes.rb to add `mount SupportChat::Engine` |
| I-5 | Create initial Settings record | Must Have | Widget token generated on first migration |
| I-6 | Compatible with Rails 6.0+ | Must Have | Tested on Rails 6.1, 7.0, 7.1 |
| I-7 | Compatible with PostgreSQL, MySQL, SQLite | Must Have | Database-agnostic migrations |
| I-8 | Provide clear error messages if setup incomplete | Must Have | Helpful errors if config missing |

---

## 7. Non-Functional Requirements

### 7.1 Performance

| Requirement | Target | Measurement |
|-------------|--------|-------------|
| Widget load time | < 500ms | Time from page load to widget visible |
| Message delivery latency | < 1 second | Time from send to recipient sees message |
| Dashboard load time | < 2 seconds | Time to display conversation list |
| API response time (95th percentile) | < 200ms | Measured under normal load |
| Support concurrent conversations | 100+ | With single Rails server + Redis |
| Database query efficiency | < 50ms | All queries indexed, N+1 avoided |

### 7.2 Scalability

- **Horizontal scaling**: Support multiple Rails servers with Redis for ActionCable
- **Database**: Indexed columns for efficient queries at 10,000+ conversations
- **WebSocket connections**: Use Redis adapter for ActionCable in production
- **Graceful degradation**: If WebSocket fails, fall back to polling (future enhancement)

### 7.3 Security

| Requirement | Implementation |
|-------------|----------------|
| Widget token validation | All public API endpoints verify token |
| Session token security | Signed using Rails.application.message_verifier (cryptographically secure) |
| SQL injection prevention | Use ActiveRecord parameterized queries |
| XSS prevention | HTML-escape all user-generated content |
| CSRF protection | Standard Rails CSRF tokens for authenticated endpoints |
| Agent authorization | Verify user has support_agent? permission |
| Rate limiting | Optional: Implement with Rack::Attack (not in MVP) |

### 7.4 Reliability

- **Error handling**: All API endpoints return appropriate HTTP status codes
- **Logging**: Log errors with context (conversation_id, user_id)
- **Graceful failures**: Widget degrades gracefully if API unavailable
- **Data integrity**: Foreign key constraints, validations on all models
- **Idempotency**: Message creation is idempotent (no duplicate messages)

### 7.5 Usability

- **Widget**: Intuitive UI, no instructions needed
- **Dashboard**: Clean, minimal interface focused on conversations
- **Setup time**: < 5 minutes from gem install to working widget
- **Documentation**: Clear examples, copy-paste ready code
- **Error messages**: User-friendly, actionable

### 7.6 Maintainability

- **Code quality**: RuboCop compliant, well-commented
- **Test coverage**: > 80% for models, controllers, channels
- **Modular design**: Easy to extend with plugins/hooks
- **Semantic versioning**: Follow semver for releases
- **Changelog**: Document all changes between versions

---

## 8. Testing Requirements

### 8.1 Unit Tests (Minitest)

**Testing Setup:**
- Dummy Rails app in `test/dummy/` for integration testing
- Minitest for all test cases
- Database-agnostic test fixtures

**Models:**
- Conversation model validations
- Message model validations and associations
- Setting model token generation
- Conversation#agent_unread_count calculation
- Message broadcasting callbacks

**Controllers:**
- WidgetController authentication via token
- ConversationsController authorization
- MessagesController message creation
- Proper HTTP status codes for all endpoints

**Channels:**
- GuestChannel subscription authorization
- AgentChannel authorization for support agents
- Message broadcasting to correct streams

**Mailers:**
- Email batching logic (30-minute delay for new conversations)
- Correct recipient and content
- Email not sent for conversations < 30 minutes old

### 8.2 Integration Tests

- Complete guest conversation flow (create, message, receive reply)
- Agent dashboard flow (view conversations, reply, close)
- WebSocket message delivery end-to-end
- Conversation persistence across sessions

### 8.3 System Tests (Capybara)

- Widget appears on page
- Guest can initiate conversation
- Guest can send and receive messages
- Agent can view and reply to conversations
- Mobile responsiveness

### 8.4 Manual Testing Checklist

- [ ] Install gem in fresh Rails app
- [ ] Widget loads without errors
- [ ] Guest can start conversation
- [ ] Messages sent in real-time
- [ ] Agent dashboard shows conversations
- [ ] Email notifications delivered
- [ ] Works in Chrome, Firefox, Safari
- [ ] Works on iOS and Android devices
- [ ] Handles network interruptions gracefully
- [ ] Multiple agents can use dashboard simultaneously

---

## 9. Documentation Requirements

### 9.1 README.md

Must include:
- **Quick start** (5-minute setup)
- **Features list** with screenshots
- **Installation instructions** (step-by-step)
- **Configuration options** with examples
- **Deployment guide** (ActionCable/Redis setup)
- **Troubleshooting** common issues
- **Contributing guidelines**
- **License** (MIT)
- **Credits** and acknowledgments

### 9.2 Code Documentation

- YARD documentation for all public methods
- Inline comments for complex logic
- Examples in method documentation
- Model associations documented

### 9.3 Wiki/Guides (Post-MVP)

- Customizing widget appearance
- Extending with custom features
- Integrating with email services
- Scaling for high traffic
- Security best practices

---

## 10. Deployment & Release

### 10.1 Gem Release Checklist

- [ ] Version number in lib/support_chat/version.rb
- [ ] CHANGELOG.md updated
- [ ] All tests passing
- [ ] RuboCop violations fixed
- [ ] README complete and accurate
- [ ] Build gem: `gem build support_chat.gemspec`
- [ ] Publish to RubyGems: `gem push support_chat-x.x.x.gem`
- [ ] Tag release in Git: `git tag v0.1.0`
- [ ] Push tags: `git push --tags`
- [ ] Create GitHub release with notes

### 10.2 Production Deployment Notes

For host applications using the gem:

**Required:**
- ActionCable configured with Redis adapter
- Redis server running (for WebSocket scaling)
- Background job processor (Sidekiq/Delayed Job) for emails

**Recommended:**
- Use CDN for widget.js for better performance
- Set up monitoring for ActionCable connections
- Configure email delivery (SendGrid, Postmark, etc.)
- Enable SSL/HTTPS (required for WebSockets)

**Example ActionCable config:**
```yaml
# config/cable.yml
production:
  adapter: redis
  url: <%= ENV.fetch("REDIS_URL") { "redis://localhost:6379/1" } %>
  channel_prefix: myapp_production
```

---

## 11. Future Enhancements (Post-MVP)

### Version 0.2.0 (4-8 weeks post-launch)
- File/image uploads in chat
- Canned responses for agents
- Typing indicators
- Conversation assignment to specific agents

### Version 0.3.0 (8-12 weeks post-launch)
- Offline message queue (when no agents online)
- Agent notes (internal comments)
- Basic analytics (conversation volume, response time)
- Conversation search

### Version 0.4.0 (3-6 months post-launch)
- Slack/Discord notifications for new messages
- Conversation tags/categories
- Advanced analytics dashboard
- Mobile app (React Native) for agents

### Version 1.0.0 (6-12 months post-launch)
- Multi-language support
- Conversation routing rules
- Business hours configuration
- SLA tracking
- Customer satisfaction ratings

---

## 12. Open Questions & Decisions Needed

### 12.1 Resolved Decisions

| Question | Decision | Rationale |
|----------|----------|-----------|
| Support user accounts or anonymous only? | Anonymous only (MVP) | Simpler to build, wider use case |
| Build separate dashboard or use host app? | Embedded in host app | Easier installation |
| Real-time via ActionCable or polling? | ActionCable | Modern, efficient, Rails-native |
| Styling: CSS framework or custom? | Minimal custom CSS | No dependencies, easy to override |
| License? | MIT | Most permissive, encourages adoption |
| User model and agent permissions? | Require host app's User model, implement support_agent? method | Maximum flexibility for different user models |
| Widget integration method? | View helper (`<%= support_chat_widget %>`) | Rails-idiomatic, hides complexity |
| Settings record creation? | During migration with after_create hook | Automatic setup, no manual steps |
| ActionCable channel authorization? | Signed tokens using Rails.application.message_verifier | No Redis dependency, secure |
| Email notification strategy? | Time-based batching (30-min delay for new conversations) | Reduces spam, better UX |
| Closed conversation messaging? | Create new conversation | Clean separation, better analytics |
| Routes mounting? | Automatic modification of routes.rb | Standard for Rails engines |
| Testing framework? | Minitest with dummy Rails app | Rails standard, simpler setup |
| Database support? | Database-agnostic migrations | Support PostgreSQL, MySQL, SQLite |
| Widget namespace? | `__sc_widget__` prefix for all globals | Avoid collisions with host app |

---

## 13. Success Criteria

### 13.1 Development Success

- [ ] All must-have features implemented
- [ ] Test coverage > 80%
- [ ] Zero critical bugs
- [ ] Documentation complete
- [ ] Successfully installed on creator's SaaS
- [ ] Gem published to RubyGems

### 13.2 Adoption Success (3 months post-launch)

- [ ] 50+ gem downloads
- [ ] 5+ GitHub stars
- [ ] 2+ external contributors
- [ ] 3+ production deployments (besides creator's)
- [ ] Positive feedback from 80%+ of users

### 13.3 Viability Success (6 months post-launch)

- [ ] Active issue resolution (< 1 week response time)
- [ ] Regular updates (1+ per month)
- [ ] Growing community engagement
- [ ] Feature requests from real users
- [ ] Consideration for v0.2.0 features

---

## 14. Timeline & Milestones

### Week 1: Foundation
- **Days 1-2**: Gem structure, Engine setup, configuration
- **Days 3-4**: Database migrations, models with validations
- **Days 5-7**: Widget API endpoints, basic controller logic

### Week 2: Real-time Communication
- **Days 8-10**: ActionCable channels setup, broadcasting
- **Days 11-12**: Widget JavaScript (UI, form, message sending)
- **Days 13-14**: Widget-backend integration, WebSocket connection

### Week 3: Agent Dashboard
- **Days 15-17**: Dashboard views (conversation list, detail)
- **Days 18-19**: Agent message sending, real-time updates
- **Days 20-21**: Email notifications, mailer setup

### Week 4: Polish & Deploy
- **Days 22-24**: Installation generator, documentation
- **Days 25-26**: Testing, bug fixes, edge cases
- **Day 27**: Install on creator's SaaS
- **Day 28**: Final polish, README, publish to RubyGems

---

## 15. Risk Assessment

| Risk | Probability | Impact | Mitigation |
|------|-------------|--------|------------|
| ActionCable complexity causes delays | Medium | High | Start with ActionCable early, use simple channels |
| Widget conflicts with existing JS on host sites | Low | Medium | Use unique namespace, minimal global variables |
| Performance issues with many concurrent chats | Low | High | Load testing in week 4, optimize queries |
| Difficult installation process | Medium | High | Automated generator, clear documentation |
| Lack of adoption post-launch | Medium | Low | Dogfood on creator's SaaS, share on social media |
| Security vulnerability discovered | Low | High | Code review, follow Rails security best practices |
| Maintenance burden too high | Medium | Medium | Keep MVP scope minimal, clear contributing guidelines |

---

## 16. Appendix

### 16.1 Glossary

- **Guest**: Website visitor using the chat widget (not authenticated)
- **Agent**: Support staff member responding to chats (authenticated user)
- **Session Token**: Unique identifier for guest's conversation, stored in localStorage
- **Widget Token**: API token that authorizes widget to communicate with backend
- **Conversation**: A series of messages between a guest and agents
- **ActionCable**: Rails' WebSocket framework for real-time features
- **Engine**: Rails plugin architecture for mountable applications

### 16.2 References

- Rails Engines Guide: https://guides.rubyonrails.org/engines.html
- ActionCable Guide: https://guides.rubyonrails.org/action_cable_overview.html
- Gem Development Guide: https://guides.rubygems.org/make-your-own-gem/
- Competitor: Chatwoot: https://github.com/chatwoot/chatwoot

### 16.3 Mockups/Wireframes

*(To be created during development)*

- Widget closed state (bubble)
- Widget open state (guest form)
- Widget chat interface (guest view)
- Agent dashboard (conversation list)
- Agent dashboard (conversation detail)

---

---

## Appendix A: Implementation Decisions Summary

The following key implementation decisions have been finalized:

1. **Agent Authorization**: Host apps must implement `support_agent?` method on their user model. No gem-provided migrations for permissions.

2. **Widget Integration**: Use view helper `<%= support_chat_widget %>` instead of manual script tags.

3. **Settings Initialization**: `SupportChat::Setting` record created during migration via `after_create` hook.

4. **Session Token Security**: Signed using `Rails.application.message_verifier` - no database lookup for ActionCable auth.

5. **Email Notifications**:
   - Conversations < 30 minutes old: no emails sent
   - Conversations >= 30 minutes old: batch agent replies
   - Send email after 2 minutes of inactivity following last agent reply

6. **Closed Conversations**: When guest messages a closed conversation, create a new conversation (don't reopen).

7. **Routes**: Install generator automatically modifies `config/routes.rb` to mount engine.

8. **Testing**: Minitest with dummy Rails app in `test/dummy/`.

9. **Database**: Use database-agnostic migrations (no PostgreSQL-specific features).

10. **Widget Namespace**: All JavaScript globals prefixed with `__sc_widget__` to avoid collisions.

---

**END OF PRD**

---

## Instructions for Implementation

This PRD is complete and ready for implementation. Key priorities:

1. **Start with database and models** - Foundation is critical
2. **Build widget API next** - Guest flow is the core feature
3. **ActionCable integration early** - Most complex part, tackle it soon
4. **Dashboard can be simple** - Basic Rails views are fine for MVP
5. **Documentation as you go** - Update README continuously

**Critical success factors:**
- Keep it simple - resist feature creep
- Make installation dead simple
- Ensure real-time messaging works reliably
- Write tests for confidence

Good luck! 🚀