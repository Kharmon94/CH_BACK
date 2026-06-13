# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Api::V1::Admin::Teams", type: :request do
  let!(:admin) do
    User.create!(
      email: "admin@example.com",
      password: "password123",
      password_confirmation: "password123",
      role: :admin
    )
  end
  let!(:user) { create_user_with_team.first }
  let!(:team) { user.teams.first }

  it "lists teams" do
    get "/api/v1/admin/teams", headers: auth_headers(admin)
    expect(response).to have_http_status(:ok)
    expect(JSON.parse(response.body).length).to be >= 1
  end

  it "overrides license tier" do
    patch "/api/v1/admin/teams/#{team.id}",
      params: { license_tier: "pro" },
      headers: auth_headers(admin),
      as: :json

    expect(response).to have_http_status(:ok)
    expect(team.reload.license.tier).to eq("pro")
  end
end
