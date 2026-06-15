# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Api::V1::Admin::Stats", type: :request do
  let!(:admin) { create_admin! }
  let!(:user) { create_user_with_team.first }
  let!(:team) { user.teams.first }

  it "returns overview stats" do
    team.update!(export_count: 7)
    team.license.update!(tier: "pro", status: "active")

    get "/api/v1/admin/stats", headers: auth_headers(admin)

    expect(response).to have_http_status(:ok)
    body = JSON.parse(response.body)

    expect(body["users_count"]).to eq(User.count)
    expect(body["admins_count"]).to eq(User.admin.count)
    expect(body["teams_count"]).to eq(Team.count)
    expect(body["pro_teams_count"]).to eq(License.where(tier: "pro").count)
    expect(body["free_teams_count"]).to eq(body["teams_count"] - body["pro_teams_count"])
    expect(body["total_exports"]).to eq(Team.sum(:export_count))
    expect(body["published_posts_count"]).to eq(BlogPost.published.count)

    expect(body["recent_users"].length).to be <= 5
    expect(body["recent_users"].first).to include("id", "email", "role", "created_at")

    expect(body["recent_teams"].length).to be <= 5
    recent_team = body["recent_teams"].find { |row| row["id"] == team.id }
    expect(recent_team).to include("id", "name", "slug", "created_at")
    expect(recent_team["license"]).to eq(
      "tier" => "pro",
      "pro" => true,
      "status" => "active"
    )
  end

  it "returns forbidden for non-admin" do
    get "/api/v1/admin/stats", headers: auth_headers(user)

    expect(response).to have_http_status(:forbidden)
  end
end
