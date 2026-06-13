# frozen_string_literal: true

class StripeService
  PLANS = {
    "monthly" => "STRIPE_PRICE_MONTHLY",
    "annual" => "STRIPE_PRICE_ANNUAL"
  }.freeze

  class << self
    def create_checkout_session(user, team, plan:)
      price_id = ENV.fetch(PLANS.fetch(plan) { raise ArgumentError, "Invalid plan" })
      frontend_url = FrontendOrigin.primary.chomp("/")

      params = {
        mode: "subscription",
        client_reference_id: team.id.to_s,
        line_items: [ { price: price_id, quantity: 1 } ],
        metadata: {
          team_id: team.id.to_s,
          user_id: user.id.to_s
        },
        success_url: "#{frontend_url}/app/teams/#{team.id}/billing?session_id={CHECKOUT_SESSION_ID}",
        cancel_url: "#{frontend_url}/pricing?checkout=cancel"
      }

      if team.stripe_customer_id.present?
        params[:customer] = team.stripe_customer_id
      else
        params[:customer_creation] = "always"
      end

      Stripe::Checkout::Session.create(params)
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
      return unless stripe_configured?

      subscription = Stripe::Subscription.retrieve(license.stripe_subscription_id)
      apply_subscription(license, subscription)
    rescue Stripe::StripeError
      nil
    end

    def handle_webhook(payload, sig_header)
      event = Stripe::Webhook.construct_event(payload, sig_header, ENV.fetch("STRIPE_WEBHOOK_SECRET"))

      case event.type
      when "checkout.session.completed"
        session = event.data.object
        team = Team.find_by(id: session.metadata["team_id"])
        user = User.find_by(id: session.metadata["user_id"])
        fulfill_pro(team, user, session) if team
      when "customer.subscription.updated"
        license = License.find_by(stripe_subscription_id: event.data.object.id)
        apply_subscription(license, event.data.object) if license
      when "customer.subscription.deleted"
        license = License.find_by(stripe_subscription_id: event.data.object.id)
        downgrade_license(license) if license
      end

      { received: true }
    end

    private

    def stripe_configured?
      ENV["STRIPE_SECRET_KEY"].present?
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
        license.update!(
          tier: "pro",
          status: subscription.status,
          expires_at: Time.at(subscription.current_period_end)
        )
      end
    end

    def downgrade_license(license)
      license.update!(tier: "free", status: nil, stripe_subscription_id: nil, expires_at: nil)
    end
  end
end
