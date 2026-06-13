class ProFeatureGate
  PRO_FORMATS = %w[agent_clone json html].freeze

  def self.allow?(format:, license_tier: "free", admin: false)
    return true if admin
    return true if license_tier == "pro"
    return false if PRO_FORMATS.include?(format)

    true
  end

  def self.agent_clone_visible?(license_tier: "free", admin: false)
    admin || license_tier == "pro"
  end
end
