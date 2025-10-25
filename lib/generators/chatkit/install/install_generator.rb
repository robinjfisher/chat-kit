# frozen_string_literal: true

require "rails/generators"
require "rails/generators/migration"

module Chatkit
  module Generators
    class InstallGenerator < Rails::Generators::Base
      include Rails::Generators::Migration

      source_root File.expand_path("templates", __dir__)
      desc "Creates ChatKit initializer, copies migrations, and mounts routes"

      def self.next_migration_number(path)
        next_migration_number = current_migration_number(path) + 1
        ActiveRecord::Migration.next_migration_number(next_migration_number)
      end

      def copy_migrations
        migration_template "create_support_chat_conversations.rb",
                          "db/migrate/create_support_chat_conversations.rb"
        migration_template "create_support_chat_messages.rb",
                          "db/migrate/create_support_chat_messages.rb"
        migration_template "create_support_chat_settings.rb",
                          "db/migrate/create_support_chat_settings.rb"
      end

      def create_initializer_file
        template "initializer.rb", "config/initializers/chatkit.rb"
      end

      def mount_engine
        route "mount SupportChat::Engine => '/support_chat'"
      end

      def show_readme
        readme "README" if behavior == :invoke
      end
    end
  end
end
