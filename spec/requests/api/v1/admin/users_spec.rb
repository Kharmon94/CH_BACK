# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Api::V1::Admin::Users", type: :request do
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

  it "lists users" do
    get "/api/v1/admin/users", headers: auth_headers(admin)
    expect(response).to have_http_status(:ok)
    emails = JSON.parse(response.body).map { |row| row["email"] }
    expect(emails).to include(user.email)
  end

  it "shows user with teams" do
    get "/api/v1/admin/users/#{user.id}", headers: auth_headers(admin)
    expect(response).to have_http_status(:ok)
    body = JSON.parse(response.body)
    expect(body["email"]).to eq(user.email)
    expect(body["teams"].length).to eq(1)
    expect(body["teams"].first["name"]).to eq(team.name)
  end
end
