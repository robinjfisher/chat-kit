# frozen_string_literal: true

module SupportChat
  class Setting < ApplicationRecord
    self.table_name = "support_chat_settings"

    validates :widget_token, presence: true, uniqueness: true
    validates :primary_color, format: { with: /\A#[0-9A-F]{6}\z/i }, allow_blank: true
    validates :widget_position, inclusion: { in: %w[bottom-right bottom-left] }

    before_validation :generate_widget_token, on: :create

    def self.current
      first_or_create!(widget_token: SecureRandom.urlsafe_base64(32))
    end

    private

    def generate_widget_token
      self.widget_token ||= SecureRandom.urlsafe_base64(32)
    end
  end
end
