# frozen_string_literal: true

class StripeService
  class << self
    def create_checkout_session(user, team, plan:)
      ensure_checkout_ready!

      params = {
        mode: "subscription",
        client_reference_id: team.id.to_s,
        line_items: [ { price: StripeConfig.price_id(plan), quantity: 1 } ],
        metadata: {
          team_id: team.id.to_s,
          user_id: user.id.to_s
        },
        success_url: "#{FrontendOrigin.primary.chomp('/')}/app/teams/#{team.id}/billing?session_id={CHECKOUT_SESSION_ID}",
        cancel_url: "#{FrontendOrigin.primary.chomp('/')}/pricing?checkout=cancel",
        allow_promotion_codes: true
      }

      if team.stripe_customer_id.present?
        params[:customer] = team.stripe_customer_id
      else
        params[:customer_creation] = "always"
      end

      Stripe::Checkout::Session.create(params)
    end

    def create_billing_portal_session(team)
      ensure_checkout_ready!
      raise ArgumentError, "Team has no Stripe customer yet" if team.stripe_customer_id.blank?

      Stripe::BillingPortal::Session.create(
        customer: team.stripe_customer_id,
        return_url: "#{FrontendOrigin.primary.chomp('/')}/app/teams/#{team.id}/billing"
      )
    end

    def confirm_checkout_session(user, team, session_id)
      session = Stripe::Checkout::Session.retrieve(session_id, expand: [ "subscription" ])
      raise ArgumentError, "Session not paid" unless session.payment_status == "paid"
      raise ArgumentError, "Session team mismatch" unless session.metadata["team_id"].to_s == team.id.to_s
      raise ArgumentError, "Session user mismatch" unless session.metadata["user_id"].to_s == user.id.to_s

      fulfill_pro(team, user, session)
    end

    def sync_subscription(license)
      return unless license&.stripe_subscription_id.present?
      return unless StripeConfig.enabled?

      subscription = Stripe::Subscription.retrieve(license.stripe_subscription_id)
      apply_subscription(license, subscription)
    rescue Stripe::StripeError
      nil
    end

    def handle_webhook(event)
      StripeConfig.configure!

      case event.type
      when "checkout.session.completed"
        session = event.data.object
        if session.payment_status == "paid"
          team = Team.find_by(id: session.metadata["team_id"])
          user = User.find_by(id: session.metadata["user_id"])
          fulfill_pro(team, user, session) if team
        end
      when "customer.subscription.updated", "customer.subscription.created"
        license = License.find_by(stripe_subscription_id: event.data.object.id)
        apply_subscription(license, event.data.object) if license
      when "customer.subscription.deleted"
        license = License.find_by(stripe_subscription_id: event.data.object.id)
        downgrade_license(license) if license
      end

      { received: true }
    end

    def verify_webhook(payload, sig_header)
      secrets = StripeConfig.webhook_secrets
      raise KeyError, "Stripe webhook secret is not configured" if secrets.empty?

      secrets.each do |secret|
        return Stripe::Webhook.construct_event(payload, sig_header, secret)
      rescue Stripe::SignatureVerificationError
        next
      end

      raise Stripe::SignatureVerificationError.new("No matching webhook secret", sig_header)
    end

    private

    def ensure_checkout_ready!
      return if StripeConfig.configured_for_checkout?

      missing = StripeConfig.missing_checkout_keys.map { |k| StripeConfig.env_hint_for(k) }.join(", ")
      raise KeyError, "Stripe is not fully configured. Set: #{missing}"
    end

    def fulfill_pro(team, user, session)
      team.update!(stripe_customer_id: session.customer) if session.customer.present?

      subscription_id =
        if session.subscription.is_a?(String)
          session.subscription
        else
          session.subscription&.id
        end

      license = team.license || team.create_license!(tier: "free")
      license.update!(
        tier: "pro",
        status: "active",
        stripe_subscription_id: subscription_id
      )

      BillingMailer.subscription_confirmed(team, user).deliver_later if user
      license
    end

    def apply_subscription(license, subscription)
      if %w[canceled unpaid incomplete_expired].include?(subscription.status)
        downgrade_license(license)
      else
        period_end = subscription.respond_to?(:current_period_end) ? subscription.current_period_end : nil
        license.update!(
          tier: "pro",
          status: subscription.status,
          expires_at: period_end ? Time.at(period_end) : nil
        )
      end
    end

    def downgrade_license(license)
      license.update!(tier: "free", status: nil, stripe_subscription_id: nil, expires_at: nil)
    end
  end
end
