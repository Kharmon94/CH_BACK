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

  it "shows team details" do
    get "/api/v1/admin/teams/#{team.id}", headers: auth_headers(admin)

    expect(response).to have_http_status(:ok)
    body = JSON.parse(response.body)
    expect(body["id"]).to eq(team.id)
    expect(body["name"]).to eq(team.name)
    expect(body["created_at"]).to be_present
    expect(body["members"].length).to eq(1)
    expect(body["members"].first["email"]).to eq(user.email)
    expect(body["workspaces"].length).to eq(1)
  end

  it "updates team name" do
    patch "/api/v1/admin/teams/#{team.id}",
      params: { name: "Renamed Team" },
      headers: auth_headers(admin),
      as: :json

    expect(response).to have_http_status(:ok)
    body = JSON.parse(response.body)
    expect(body["name"]).to eq("Renamed Team")
    expect(team.reload.name).to eq("Renamed Team")
  end

  it "overrides license tier" do
    patch "/api/v1/admin/teams/#{team.id}",
      params: { license_tier: "pro" },
      headers: auth_headers(admin),
      as: :json

    expect(response).to have_http_status(:ok)
    expect(team.reload.license.tier).to eq("pro")
  end

  it "rejects invalid license tier" do
    patch "/api/v1/admin/teams/#{team.id}",
      params: { license_tier: "enterprise" },
      headers: auth_headers(admin),
      as: :json

    expect(response).to have_http_status(:unprocessable_entity)
    expect(JSON.parse(response.body)["error"]).to eq("Invalid tier")
  end

  it "returns forbidden for non-admin" do
    get "/api/v1/admin/teams", headers: auth_headers(user)
    expect(response).to have_http_status(:forbidden)

    patch "/api/v1/admin/teams/#{team.id}",
      params: { name: "Blocked" },
      headers: auth_headers(user),
      as: :json
    expect(response).to have_http_status(:forbidden)
  end
end
