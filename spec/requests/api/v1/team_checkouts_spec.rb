# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Api::V1::TeamCheckouts", type: :request do
  let!(:owner) { create_user_with_team.first }
  let!(:team) { owner.teams.first }

  before do
    allow(StripeConfig).to receive(:configured_for_checkout?).and_return(true)
    allow(StripeConfig).to receive(:price_id).with("monthly").and_return("price_test")
    allow(StripeConfig).to receive(:price_id).with("annual").and_return("price_test_annual")
    allow(Stripe::Checkout::Session).to receive(:create).and_return(
      double(url: "https://checkout.stripe.test/session")
    )
  end

  it "allows owner checkout" do
    post "/api/v1/teams/#{team.id}/billing/checkout",
      params: { plan: "monthly" },
      headers: auth_headers(owner, team: team),
      as: :json

    expect(response).to have_http_status(:ok)
    expect(JSON.parse(response.body)["url"]).to include("stripe")
  end

  it "forbids member checkout" do
    member = User.create!(
      email: "member2@example.com",
      password: "password123",
      password_confirmation: "password123",
      role: :user
    )
    TeamMembership.create!(user: member, team: team, role: :member)

    post "/api/v1/teams/#{team.id}/billing/checkout",
      params: { plan: "monthly" },
      headers: auth_headers(member, team: team),
      as: :json

    expect(response).to have_http_status(:forbidden)
  end

  it "returns portal url for pro team with stripe customer" do
    team.update!(stripe_customer_id: "cus_test")
    team.license.update!(tier: "pro", stripe_subscription_id: "sub_test")
    allow(Stripe::BillingPortal::Session).to receive(:create).and_return(
      double(url: "https://billing.stripe.test/portal")
    )

    post "/api/v1/teams/#{team.id}/billing/portal",
      headers: auth_headers(owner, team: team),
      as: :json

    expect(response).to have_http_status(:ok)
    expect(JSON.parse(response.body)["url"]).to include("stripe")
  end
end
