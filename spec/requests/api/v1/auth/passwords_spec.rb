# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Api::V1::Auth::Passwords", type: :request do
  let!(:user) { create_user_with_team.first }

  describe "POST /auth/forgot_password" do
    it "returns ok for existing user email" do
      expect do
        post "/api/v1/auth/forgot_password",
          params: { email: user.email },
          headers: json_headers,
          as: :json
      end.to change { ActionMailer::Base.deliveries.size }.by(1)

      expect(response).to have_http_status(:ok)
    end

    it "returns ok for unknown email without sending mail" do
      expect do
        post "/api/v1/auth/forgot_password",
          params: { email: "missing@example.com" },
          headers: json_headers,
          as: :json
      end.not_to change { ActionMailer::Base.deliveries.size }

      expect(response).to have_http_status(:ok)
    end

    it "does not send mail for admin accounts" do
      admin = User.create!(
        email: "admin@example.com",
        password: "password123",
        password_confirmation: "password123",
        role: :admin
      )

      expect do
        post "/api/v1/auth/forgot_password",
          params: { email: admin.email },
          headers: json_headers,
          as: :json
      end.not_to change { ActionMailer::Base.deliveries.size }

      expect(response).to have_http_status(:ok)
    end
  end

  describe "POST /auth/reset_password" do
    it "resets password with valid token" do
      token = user.send_reset_password_instructions
      raw_token = token

      post "/api/v1/auth/reset_password",
        params: {
          reset_password_token: raw_token,
          password: "newpassword123",
          password_confirmation: "newpassword123"
        },
        headers: json_headers,
        as: :json

      expect(response).to have_http_status(:ok)
      expect(user.reload.valid_password?("newpassword123")).to be(true)
    end

    it "rejects invalid token" do
      post "/api/v1/auth/reset_password",
        params: {
          reset_password_token: "invalid",
          password: "newpassword123",
          password_confirmation: "newpassword123"
        },
        headers: json_headers,
        as: :json

      expect(response).to have_http_status(:unprocessable_entity)
    end
  end
end
