# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Api::V1::Admin::Licenses", type: :request do
  let!(:admin) { create_admin! }
  let!(:user) { create_user_with_team.first }
  let!(:team) { user.teams.first }

  it "lists licenses for all teams" do
    team.license.update!(tier: "pro", status: "active")

    get "/api/v1/admin/licenses", headers: auth_headers(admin)

    expect(response).to have_http_status(:ok)
    rows = JSON.parse(response.body)
    row = rows.find { |entry| entry["team_id"] == team.id }

    expect(row).to include(
      "team_id" => team.id,
      "team_name" => team.name,
      "team_slug" => team.slug,
      "tier" => "pro",
      "pro" => true,
      "status" => "active",
      "export_count" => team.export_count,
      "member_count" => team.team_memberships.count
    )
  end

  it "filters pro licenses" do
    team.license.update!(tier: "pro", status: "active")

    get "/api/v1/admin/licenses", params: { tier: "pro" }, headers: auth_headers(admin)

    expect(response).to have_http_status(:ok)
    rows = JSON.parse(response.body)
    expect(rows).to all(include("tier" => "pro"))
    expect(rows.map { |row| row["team_id"] }).to include(team.id)
  end

  it "filters free licenses including teams without a license row" do
    team.license.destroy!

    get "/api/v1/admin/licenses", params: { tier: "free" }, headers: auth_headers(admin)

    expect(response).to have_http_status(:ok)
    rows = JSON.parse(response.body)
    row = rows.find { |entry| entry["team_id"] == team.id }

    expect(row).to include("tier" => "free", "pro" => false, "status" => nil)
  end

  it "returns forbidden for non-admin" do
    get "/api/v1/admin/licenses", headers: auth_headers(user)

    expect(response).to have_http_status(:forbidden)
  end
end
