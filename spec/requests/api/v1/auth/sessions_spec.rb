# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Api::V1::Auth::Sessions", type: :request do
  let!(:user) { create_user_with_team.first }

  it "signs in with valid credentials" do
    post "/api/v1/auth/sign_in",
      params: { email: user.email, password: "password123" },
      headers: json_headers,
      as: :json

    expect(response).to have_http_status(:ok)
    body = JSON.parse(response.body)
    expect(body["token"]).to be_present
    expect(body["user"]["email"]).to eq(user.email)
    expect(body["user"]["role"]).to eq("user")
  end

  it "rejects invalid credentials" do
    post "/api/v1/auth/sign_in",
      params: { email: user.email, password: "wrong" },
      headers: json_headers,
      as: :json

    expect(response).to have_http_status(:unauthorized)
  end

  it "rejects admin accounts" do
    admin = User.create!(
      email: "admin@example.com",
      password: "password123",
      password_confirmation: "password123",
      role: :admin
    )

    post "/api/v1/auth/sign_in",
      params: { email: admin.email, password: "password123" },
      headers: json_headers,
      as: :json

    expect(response).to have_http_status(:forbidden)
  end
end
