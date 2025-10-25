# frozen_string_literal: true

class User < ApplicationRecord
  def support_agent?
    admin?
  end

  def admin?
    role == "admin"
  end
end
