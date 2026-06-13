# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Api::V1::Workspaces", type: :request do
  let!(:user) { create_user_with_team.first }
  let!(:team) { user.teams.first }
  let!(:workspace) { team.workspaces.first }

  it "lists workspaces for a team" do
    get "/api/v1/teams/#{team.id}/workspaces", headers: auth_headers(user, team: team)
    expect(response).to have_http_status(:ok)
    expect(JSON.parse(response.body).length).to eq(1)
  end

  it "creates a workspace" do
    post "/api/v1/teams/#{team.id}/workspaces",
      params: { name: "Side Project", root_path: "/home/proj" },
      headers: auth_headers(user, team: team),
      as: :json

    expect(response).to have_http_status(:created)
    body = JSON.parse(response.body)
    expect(body["name"]).to eq("Side Project")
    expect(body["root_path"]).to eq("/home/proj")
  end

  it "updates a workspace" do
    patch "/api/v1/teams/#{team.id}/workspaces/#{workspace.id}",
      params: { name: "Renamed" },
      headers: auth_headers(user, team: team),
      as: :json

    expect(response).to have_http_status(:ok)
    expect(JSON.parse(response.body)["name"]).to eq("Renamed")
  end
end
