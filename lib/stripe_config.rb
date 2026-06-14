# frozen_string_literal: true

# Resolves Stripe keys and price IDs for test vs live mode.
# Set STRIPE_MODE=test|live (defaults to test in development/test, live in production).
module StripeConfig
  MODES = %w[test live].freeze
  REQUIRED_CHECKOUT_KEYS = %w[secret_key price_monthly price_annual].freeze

  module_function

  def mode
    explicit = ENV["STRIPE_MODE"].to_s.strip.downcase
    return explicit if MODES.include?(explicit)

    Rails.env.production? ? "live" : "test"
  end

  def configure!
    key = secret_key
    Stripe.api_key = key if key.present?
  end

  def enabled?
    secret_key.present?
  end

  def configured_for_checkout?
    missing_checkout_keys.empty?
  end

  def missing_checkout_keys
    REQUIRED_CHECKOUT_KEYS.select { |name| resolve(name).blank? }
  end

  def secret_key
    resolve("secret_key")
  end

  def webhook_secrets
    [
      resolve("webhook_secret"),
      ENV["STRIPE_WEBHOOK_SECRET"].to_s.strip.presence,
      ENV["STRIPE_WEBHOOK_SECRET_TEST"].to_s.strip.presence,
      ENV["STRIPE_WEBHOOK_SECRET_LIVE"].to_s.strip.presence
    ].compact.uniq
  end

  def price_id(plan)
    key = plan.to_s == "annual" ? "price_annual" : "price_monthly"
    resolve(key) || raise(KeyError, "Missing Stripe price for #{plan} (set STRIPE_PRICE_#{plan.to_s.upcase} or mode-specific variant)")
  end

  def status_payload
    {
      mode: mode,
      enabled: enabled?,
      checkout_ready: configured_for_checkout?,
      missing: missing_checkout_keys.map { |k| env_hint_for(k) },
      webhook_secrets_configured: webhook_secrets.any?
    }
  end

  def resolve(name)
    case name
    when "secret_key"
      mode_key("STRIPE_SECRET_KEY") || ENV["STRIPE_SECRET_KEY"].to_s.strip.presence
    when "webhook_secret"
      mode_key("STRIPE_WEBHOOK_SECRET") || ENV["STRIPE_WEBHOOK_SECRET"].to_s.strip.presence
    when "price_monthly"
      mode_key("STRIPE_PRICE_MONTHLY") || ENV["STRIPE_PRICE_MONTHLY"].to_s.strip.presence
    when "price_annual"
      mode_key("STRIPE_PRICE_ANNUAL") || ENV["STRIPE_PRICE_ANNUAL"].to_s.strip.presence
    end
  end

  def mode_key(base)
    suffix = mode == "live" ? "_LIVE" : "_TEST"
    ENV["#{base}#{suffix}"].to_s.strip.presence
  end

  def env_hint_for(key)
    case key
    when "secret_key" then mode == "live" ? "STRIPE_SECRET_KEY_LIVE or STRIPE_SECRET_KEY" : "STRIPE_SECRET_KEY_TEST or STRIPE_SECRET_KEY"
    when "price_monthly" then "STRIPE_PRICE_MONTHLY_TEST or STRIPE_PRICE_MONTHLY"
    when "price_annual" then "STRIPE_PRICE_ANNUAL_TEST or STRIPE_PRICE_ANNUAL"
    else key
    end
  end
end
