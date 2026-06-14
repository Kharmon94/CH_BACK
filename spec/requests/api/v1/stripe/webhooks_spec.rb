require "rails_helper"

RSpec.describe "Api::V1::Stripe::Webhooks", type: :request do
  let!(:user) { create_user_with_team.first }
  let!(:team) { user.teams.first }

  before do
    allow(StripeConfig).to receive(:webhook_secrets).and_return([ "whsec_test" ])
  end

  describe "POST /api/v1/stripe/webhook" do
    it "returns 400 on invalid signature" do
      allow(StripeService).to receive(:verify_webhook).and_raise(
        ::Stripe::SignatureVerificationError.new("bad sig", "sig_header")
      )

      post "/api/v1/stripe/webhook",
           params: "{}",
           headers: { "Stripe-Signature" => "bad" }

      expect(response).to have_http_status(:bad_request)
    end

    it "upgrades team license on checkout.session.completed" do
      session_object = Struct.new(
        :payment_status, :metadata, :client_reference_id, :customer, :subscription
      ).new(
        "paid",
        { "team_id" => team.id.to_s, "user_id" => user.id.to_s },
        team.id.to_s,
        "cus_webhook",
        "sub_webhook"
      )
      event = double("Stripe::Event", type: "checkout.session.completed", data: double(object: session_object))

      allow(StripeService).to receive(:verify_webhook).and_return(event)
      allow(StripeService).to receive(:handle_webhook).and_call_original

      post "/api/v1/stripe/webhook",
           params: "{}",
           headers: { "Stripe-Signature" => "valid" }

      expect(response).to have_http_status(:ok)
      expect(team.license.reload.tier).to eq("pro")
      expect(team.reload.stripe_customer_id).to eq("cus_webhook")
    end
  end
end
