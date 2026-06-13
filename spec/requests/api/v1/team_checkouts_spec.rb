# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Api::V1::TeamCheckouts", type: :request do
  let!(:owner) { create_user_with_team.first }
  let!(:team) { owner.teams.first }

  before do
    allow(Stripe::Checkout::Session).to receive(:create).and_return(
      double(url: "https://checkout.stripe.test/session")
    )
    stub_const("StripeService::PLANS", { "monthly" => "STRIPE_PRICE_MONTHLY" })
    allow(ENV).to receive(:fetch).and_call_original
    allow(ENV).to receive(:fetch).with("STRIPE_PRICE_MONTHLY").and_return("price_test")
    allow(ENV).to receive(:fetch).with("FRONTEND_ORIGIN", anything).and_return("http://localhost:5173")
    allow(ENV).to receive(:fetch).with("FRONTEND_URL", anything).and_return("http://localhost:5173")
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
end
