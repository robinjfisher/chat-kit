# frozen_string_literal: true

require "test_helper"

module SupportChat
  class SettingTest < ActiveSupport::TestCase
    test "generates widget token on create" do
      setting = Setting.create!

      assert_not_nil setting.widget_token
      assert setting.widget_token.length >= 32
    end

    test "validates widget token presence" do
      setting = Setting.new(widget_token: nil)

      assert_not setting.valid?
      assert_includes setting.errors[:widget_token], "can't be blank"
    end

    test "validates widget token uniqueness" do
      setting1 = Setting.create!
      setting2 = Setting.new(widget_token: setting1.widget_token)

      assert_not setting2.valid?
      assert_includes setting2.errors[:widget_token], "has already been taken"
    end

    test "validates primary_color format" do
      setting = Setting.new(primary_color: "invalid")

      assert_not setting.valid?
      assert_includes setting.errors[:primary_color], "is invalid"
    end

    test "accepts valid hex colors" do
      setting = Setting.new(primary_color: "#FF5733")

      setting.validate
      assert_empty setting.errors[:primary_color]
    end

    test "validates widget_position inclusion" do
      setting = Setting.new(widget_position: "invalid")

      assert_not setting.valid?
      assert_includes setting.errors[:widget_position], "is not included in the list"
    end

    test "defaults to correct values" do
      setting = Setting.create!

      assert_equal "#4F46E5", setting.primary_color
      assert_equal "bottom-right", setting.widget_position
      assert_equal "Hi! How can we help you today?", setting.greeting_message
      assert_equal true, setting.enabled
    end

    test "current returns first or creates setting" do
      assert_difference "Setting.count", 1 do
        setting = Setting.current
        assert_not_nil setting
        assert_not_nil setting.widget_token
      end

      # Second call should not create another
      assert_no_difference "Setting.count" do
        setting = Setting.current
        assert_not_nil setting
      end
    end
  end
end
