// ChatKit Widget - Open Source Customer Support Chat
// Uses __sc_widget__ prefix to avoid collisions

(function() {
  'use strict';

  // Widget namespace
  window.SupportChatWidget = {
    config: null,
    sessionToken: null,
    cable: null,
    channel: null,
    isOpen: false,

    init: function(config) {
      this.config = config;
      this.sessionToken = localStorage.getItem('__sc_widget__session_token');
      this.render();
      this.attachEventListeners();

      if (this.sessionToken) {
        this.loadExistingConversation();
      }
    },

    render: function() {
      const widgetHTML = `
        <div id="__sc_widget__container" class="__sc_widget__container">
          <!-- Chat Bubble -->
          <div id="__sc_widget__bubble" class="__sc_widget__bubble">
            <svg width="24" height="24" viewBox="0 0 24 24" fill="none">
              <path d="M20 2H4C2.9 2 2 2.9 2 4V22L6 18H20C21.1 18 22 17.1 22 16V4C22 2.9 21.1 2 20 2Z" fill="white"/>
            </svg>
            <span id="__sc_widget__unread_badge" class="__sc_widget__unread_badge" style="display: none;">0</span>
          </div>

          <!-- Chat Window -->
          <div id="__sc_widget__window" class="__sc_widget__window" style="display: none;">
            <!-- Header -->
            <div class="__sc_widget__header">
              <div>
                <h3>${this.config.businessName || 'Support Chat'}</h3>
                <p>We're here to help</p>
              </div>
              <button id="__sc_widget__close" class="__sc_widget__close_btn">×</button>
            </div>

            <!-- Guest Form (shown initially) -->
            <div id="__sc_widget__guest_form" class="__sc_widget__guest_form">
              <p class="__sc_widget__greeting">${this.config.greetingMessage}</p>
              <input type="text" id="__sc_widget__guest_name" placeholder="Your name" required />
              <input type="email" id="__sc_widget__guest_email" placeholder="Your email" required />
              <textarea id="__sc_widget__initial_message" placeholder="How can we help you?" rows="3" required></textarea>
              <button id="__sc_widget__start_chat">Start Chat</button>
            </div>

            <!-- Chat Interface (shown after starting) -->
            <div id="__sc_widget__chat" style="display: none;">
              <div id="__sc_widget__messages" class="__sc_widget__messages"></div>
              <div class="__sc_widget__input_container">
                <textarea
                  id="__sc_widget__message_input"
                  placeholder="Type your message..."
                  rows="1"
                ></textarea>
                <button id="__sc_widget__send">Send</button>
              </div>
              <div class="__sc_widget__actions">
                <button id="__sc_widget__close_conversation" class="__sc_widget__close_conversation_btn">Close Conversation</button>
              </div>
              <div class="__sc_widget__footer">
                Powered by <a href="https://github.com/robinjfisher/chat-kit" target="_blank" rel="noopener noreferrer">ChatKit</a>
              </div>
            </div>
          </div>
        </div>
      `;

      document.body.insertAdjacentHTML('beforeend', widgetHTML);
      this.applyCustomStyles();
    },

    applyCustomStyles: function() {
      const primaryColor = this.config.primaryColor || '#4F46E5';
      const position = this.config.position || 'bottom-right';

      const container = document.getElementById('__sc_widget__container');
      container.style.setProperty('--primary-color', primaryColor);

      if (position === 'bottom-left') {
        container.style.left = '20px';
        container.style.right = 'auto';
      }
    },

    attachEventListeners: function() {
      const bubble = document.getElementById('__sc_widget__bubble');
      const closeBtn = document.getElementById('__sc_widget__close');
      const startChatBtn = document.getElementById('__sc_widget__start_chat');
      const sendBtn = document.getElementById('__sc_widget__send');
      const messageInput = document.getElementById('__sc_widget__message_input');
      const closeConversationBtn = document.getElementById('__sc_widget__close_conversation');

      bubble.addEventListener('click', () => this.toggleWindow());
      closeBtn.addEventListener('click', () => this.toggleWindow());
      startChatBtn.addEventListener('click', () => this.startConversation());
      sendBtn.addEventListener('click', () => this.sendMessage());
      closeConversationBtn.addEventListener('click', () => this.closeConversation());
      messageInput.addEventListener('keypress', (e) => {
        if (e.key === 'Enter' && !e.shiftKey) {
          e.preventDefault();
          this.sendMessage();
        }
      });
    },

    toggleWindow: function() {
      const window = document.getElementById('__sc_widget__window');
      const bubble = document.getElementById('__sc_widget__bubble');

      if (this.isOpen) {
        window.style.display = 'none';
        bubble.style.display = 'flex';
        this.isOpen = false;
      } else {
        window.style.display = 'flex';
        bubble.style.display = 'none';
        this.isOpen = true;
        this.clearUnreadBadge();
      }
    },

    startConversation: function() {
      const name = document.getElementById('__sc_widget__guest_name').value.trim();
      const email = document.getElementById('__sc_widget__guest_email').value.trim();
      const initialMessage = document.getElementById('__sc_widget__initial_message').value.trim();

      if (!name || !email || !initialMessage) {
        alert('Please fill in all fields');
        return;
      }

      fetch(`${this.config.apiUrl}/widget/conversations`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'X-Widget-Token': this.config.widgetToken
        },
        body: JSON.stringify({
          guest_name: name,
          guest_email: email,
          page_url: window.location.href,
          initial_message: initialMessage
        })
      })
      .then(response => response.json())
      .then(data => {
        if (data.session_token) {
          this.sessionToken = data.session_token;
          localStorage.setItem('__sc_widget__session_token', data.session_token);
          this.showChatInterface();
          this.connectWebSocket();
        } else {
          alert('Failed to start conversation. Please try again.');
        }
      })
      .catch(error => {
        console.error('ChatKit error:', error);
        alert('Connection error. Please try again.');
      });
    },

    loadExistingConversation: function() {
      fetch(`${this.config.apiUrl}/widget/messages/${this.sessionToken}`, {
        headers: {
          'X-Widget-Token': this.config.widgetToken
        }
      })
      .then(response => response.json())
      .then(data => {
        if (data.messages) {
          this.showChatInterface();
          data.messages.forEach(msg => this.displayMessage(msg));

          // Check if conversation is closed
          if (data.conversation_status === 'closed') {
            this.disableConversation();
          } else {
            this.connectWebSocket();
          }
        } else {
          // Invalid session, clear it
          localStorage.removeItem('__sc_widget__session_token');
          this.sessionToken = null;
        }
      })
      .catch(error => {
        console.error('ChatKit error:', error);
      });
    },

    showChatInterface: function() {
      document.getElementById('__sc_widget__guest_form').style.display = 'none';
      document.getElementById('__sc_widget__chat').style.display = 'flex';
    },

    connectWebSocket: function() {
      // Use ActionCable to connect
      this.cable = ActionCable.createConsumer(`${this.config.apiUrl}/cable`);

      this.channel = this.cable.subscriptions.create(
        {
          channel: 'SupportChat::GuestChannel',
          session_token: this.sessionToken
        },
        {
          received: (data) => {
            this.displayMessage(data);
            if (!this.isOpen) {
              this.incrementUnreadBadge();
            }
          }
        }
      );
    },

    sendMessage: function() {
      const input = document.getElementById('__sc_widget__message_input');
      const content = input.value.trim();

      if (!content) return;

      fetch(`${this.config.apiUrl}/widget/messages`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'X-Widget-Token': this.config.widgetToken
        },
        body: JSON.stringify({
          session_token: this.sessionToken,
          content: content
        })
      })
      .then(response => response.json())
      .then(data => {
        if (data.success) {
          input.value = '';
          input.style.height = 'auto';
        }
      })
      .catch(error => {
        console.error('ChatKit error:', error);
      });
    },

    displayMessage: function(message) {
      const messagesContainer = document.getElementById('__sc_widget__messages');
      const messageEl = document.createElement('div');
      messageEl.className = `__sc_widget__message __sc_widget__message_${message.sender_type}`;

      const time = new Date(message.created_at).toLocaleTimeString([], {
        hour: '2-digit',
        minute: '2-digit'
      });

      messageEl.innerHTML = `
        <div class="__sc_widget__message_content">${this.escapeHtml(message.content)}</div>
        <div class="__sc_widget__message_time">${time}</div>
      `;

      messagesContainer.appendChild(messageEl);
      messagesContainer.scrollTop = messagesContainer.scrollHeight;
    },

    incrementUnreadBadge: function() {
      const badge = document.getElementById('__sc_widget__unread_badge');
      const current = parseInt(badge.textContent) || 0;
      badge.textContent = current + 1;
      badge.style.display = 'flex';
    },

    clearUnreadBadge: function() {
      const badge = document.getElementById('__sc_widget__unread_badge');
      badge.textContent = '0';
      badge.style.display = 'none';
    },

    closeConversation: function() {
      if (!confirm('Are you sure you want to close this conversation?')) {
        return;
      }

      fetch(`${this.config.apiUrl}/widget/conversations/close`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'X-Widget-Token': this.config.widgetToken
        },
        body: JSON.stringify({
          session_token: this.sessionToken
        })
      })
      .then(response => response.json())
      .then(data => {
        if (data.success) {
          this.disableConversation();
          alert('Conversation closed. Thank you for contacting us!');
        } else {
          alert('Failed to close conversation. Please try again.');
        }
      })
      .catch(error => {
        console.error('ChatKit error:', error);
        alert('Connection error. Please try again.');
      });
    },

    disableConversation: function() {
      const messageInput = document.getElementById('__sc_widget__message_input');
      const sendBtn = document.getElementById('__sc_widget__send');
      const closeBtn = document.getElementById('__sc_widget__close_conversation');

      // Disable input and buttons
      messageInput.disabled = true;
      messageInput.placeholder = 'This conversation is closed';
      sendBtn.disabled = true;
      closeBtn.style.display = 'none';

      // Disconnect websocket if connected
      if (this.channel) {
        this.channel.unsubscribe();
      }

      // Add a system message
      const messagesContainer = document.getElementById('__sc_widget__messages');
      const systemMessage = document.createElement('div');
      systemMessage.className = '__sc_widget__system_message';
      systemMessage.textContent = 'This conversation has been closed.';
      messagesContainer.appendChild(systemMessage);
      messagesContainer.scrollTop = messagesContainer.scrollHeight;
    },

    escapeHtml: function(text) {
      const div = document.createElement('div');
      div.textContent = text;
      return div.innerHTML;
    }
  };

  // Auto-initialize if config is present
  if (window.__SupportChatConfig__) {
    document.addEventListener('DOMContentLoaded', function() {
      SupportChatWidget.init(window.__SupportChatConfig__);
    });
  }
})();
