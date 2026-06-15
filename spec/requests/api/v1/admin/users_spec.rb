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

  it "updates user name and role" do
    patch "/api/v1/admin/users/#{user.id}",
      params: { name: "Updated Name", role: "admin" },
      headers: auth_headers(admin),
      as: :json

    expect(response).to have_http_status(:ok)
    body = JSON.parse(response.body)
    expect(body["name"]).to eq("Updated Name")
    expect(body["role"]).to eq("admin")
    expect(body["teams"].length).to eq(1)
    expect(user.reload.name).to eq("Updated Name")
    expect(user.admin?).to be(true)
  end

  it "rejects invalid role" do
    patch "/api/v1/admin/users/#{user.id}",
      params: { role: "superadmin" },
      headers: auth_headers(admin),
      as: :json

    expect(response).to have_http_status(:unprocessable_entity)
    expect(JSON.parse(response.body)["error"]).to eq("Invalid role")
  end

  it "blocks demoting the last admin" do
    patch "/api/v1/admin/users/#{admin.id}",
      params: { role: "user" },
      headers: auth_headers(admin),
      as: :json

    expect(response).to have_http_status(:unprocessable_entity)
    expect(JSON.parse(response.body)["error"]).to eq("Cannot demote the last admin")
    expect(admin.reload.admin?).to be(true)
  end

  it "blocks self-demotion when another admin exists" do
    other_admin = User.create!(
      email: "other-admin@example.com",
      password: "password123",
      password_confirmation: "password123",
      role: :admin
    )

    patch "/api/v1/admin/users/#{admin.id}",
      params: { role: "user" },
      headers: auth_headers(admin),
      as: :json

    expect(response).to have_http_status(:unprocessable_entity)
    expect(JSON.parse(response.body)["error"]).to eq("Cannot demote yourself")
    expect(admin.reload.admin?).to be(true)
    expect(other_admin.admin?).to be(true)
  end

  it "returns forbidden for non-admin" do
    get "/api/v1/admin/users", headers: auth_headers(user)
    expect(response).to have_http_status(:forbidden)

    patch "/api/v1/admin/users/#{user.id}",
      params: { name: "Blocked" },
      headers: auth_headers(user),
      as: :json
    expect(response).to have_http_status(:forbidden)
  end
end
