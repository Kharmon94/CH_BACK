# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Api::V1::Teams", type: :request do
  let!(:user) { create_user_with_team.first }
  let!(:team) { user.teams.first }

  it "lists teams for current user" do
    get "/api/v1/teams", headers: auth_headers(user)
    expect(response).to have_http_status(:ok)
    expect(JSON.parse(response.body).length).to eq(1)
  end

  it "creates a team" do
    post "/api/v1/teams", params: { name: "Acme" }, headers: auth_headers(user), as: :json
    expect(response).to have_http_status(:created)
    body = JSON.parse(response.body)
    expect(body["name"]).to eq("Acme")
  end

  it "invites and accepts a member" do
    invitee = User.create!(
      email: "member@example.com",
      password: "password123",
      password_confirmation: "password123",
      role: :user
    )

    post "/api/v1/teams/#{team.id}/memberships",
      params: { email: invitee.email, role: "member" },
      headers: auth_headers(user),
      as: :json
    expect(response).to have_http_status(:created)
    invite = team.team_invites.last
    expect(invite).to be_present

    post "/api/v1/team_invites/#{invite.token}/accept", headers: auth_headers(invitee)
    expect(response).to have_http_status(:ok)
    expect(team.reload.users).to include(invitee)
  end
end
