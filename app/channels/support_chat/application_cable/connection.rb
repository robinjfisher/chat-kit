# frozen_string_literal: true

module SupportChat
  module ApplicationCable
    class Connection < ActionCable::Connection::Base
      # Allow all connections - channels will handle their own authorization
      def connect
        # Accept all connections
      end
    end
  end
end
