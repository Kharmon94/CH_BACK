require "rails_helper"

RSpec.describe "Api::V1::Stripe::Status", type: :request do
  describe "GET /api/v1/stripe/status" do
    it "returns stripe configuration status" do
      allow(StripeConfig).to receive(:status_payload).and_return(
        mode: "test",
        enabled: true,
        checkout_ready: false,
        missing: [ "STRIPE_PRICE_MONTHLY" ],
        webhook_secrets_configured: true
      )

      get "/api/v1/stripe/status"

      expect(response).to have_http_status(:ok)
      body = JSON.parse(response.body)
      expect(body["mode"]).to eq("test")
      expect(body["checkout_ready"]).to be(false)
    end
  end
end
