# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Api::V1::Auth::Me", type: :request do
  let!(:user) { create_user_with_team.first }
  let!(:team) { user.teams.first }

  it "requires bearer token" do
    get "/api/v1/auth/me", headers: json_headers
    expect(response).to have_http_status(:unauthorized)
  end

  it "returns user and teams" do
    get "/api/v1/auth/me", headers: auth_headers(user, team: team)

    expect(response).to have_http_status(:ok)
    body = JSON.parse(response.body)
    expect(body["user"]["email"]).to eq(user.email)
    expect(body["user"]["teams"].length).to eq(1)
    expect(body["user"]["teams"].first["name"]).to be_present
  end

  it "updates name and avatar" do
    file = fixture_file_upload(Rails.root.join("spec/fixtures/files/test.png"), "image/png")

    post "/api/v1/uploads",
      params: { file: file },
      headers: auth_headers(user, team: team).except("Content-Type")

    signed_id = JSON.parse(response.body)["signed_id"]

    patch "/api/v1/auth/me",
      params: { name: "Updated Name", avatar_signed_id: signed_id },
      headers: auth_headers(user, team: team),
      as: :json

    expect(response).to have_http_status(:ok)
    body = JSON.parse(response.body)
    expect(body["user"]["name"]).to eq("Updated Name")
    expect(body["user"]["avatar_url"]).to be_present
    expect(user.reload.name).to eq("Updated Name")
    expect(user.avatar).to be_attached
  end
end
