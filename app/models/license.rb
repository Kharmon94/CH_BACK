# frozen_string_literal: true

class License < ApplicationRecord
  belongs_to :team

  TIERS = %w[free pro].freeze
  ACTIVE_STATUSES = %w[active trialing].freeze

  validates :tier, inclusion: { in: TIERS }

  def pro?
    tier == "pro" && active?
  end

  def active?
    return true if tier == "pro" && status.blank?

    return false unless ACTIVE_STATUSES.include?(status)

    expires_at.nil? || expires_at > Time.current
  end
end
