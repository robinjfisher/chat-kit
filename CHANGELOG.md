# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.1.0] - 2025-10-25

### Added
- Initial release of ChatKit
- Rails Engine for embeddable customer support chat
- Real-time messaging via ActionCable (WebSockets)
- Guest conversation system with anonymous chat
- Signed session tokens for guest authentication
- Widget token authentication for public API
- Customizable JavaScript widget with:
  - Guest name/email collection form
  - Real-time message display
  - Unread message badges
  - Mobile responsive design
  - Customizable colors and positioning
  - localStorage session persistence
- Admin dashboard with:
  - Conversation list (open/closed tabs)
  - Full conversation history view
  - Real-time message notifications
  - Reply functionality
  - Conversation closing
  - Unread message indicators
- Email notifications:
  - Smart batching (30-minute delay for new conversations)
  - Delayed delivery (2 minutes after last agent reply)
  - HTML and plain text formats
- Database models:
  - `Conversation` - Guest conversations with session management
  - `Message` - Polymorphic messages (guest/agent)
  - `Setting` - Widget configuration singleton
- Installation generator (`rails generate chatkit:install`):
  - Automatic migration copying
  - Initializer generation
  - Route mounting
  - Setup instructions
- Comprehensive test suite:
  - 32 model tests
  - 20+ controller tests
  - 8 channel tests
  - Integration with dummy Rails app
- View helper for easy embedding (`<%= chatkit_widget %>`)
- Database-agnostic migrations (PostgreSQL, MySQL, SQLite)
- Security features:
  - Signed session tokens using Rails message verifier
  - Widget token validation
  - Agent authorization via configurable method
  - XSS prevention with HTML escaping
- Performance optimizations:
  - Proper database indexing
  - N+1 query prevention
  - ActionCable broadcasting
- Complete documentation:
  - Comprehensive README
  - Installation guide
  - Configuration instructions
  - Widget customization examples
  - Technical architecture details

### Notes
- Requires Rails >= 6.0.0
- Requires Ruby >= 2.7.0
- No Redis dependency for single-server deployments
- Async adapter sufficient for MVP usage

[Unreleased]: https://github.com/robinfisher/chatkit/compare/v0.1.0...HEAD
[0.1.0]: https://github.com/robinfisher/chatkit/releases/tag/v0.1.0
