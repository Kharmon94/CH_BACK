# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Api::V1::Uploads", type: :request do
  let!(:user) { create_user_with_team.first }
  let!(:team) { user.teams.first }

  it "returns signed_id for image upload" do
    file = fixture_file_upload(Rails.root.join("spec/fixtures/files/test.png"), "image/png")

    post "/api/v1/uploads",
      params: { file: file },
      headers: auth_headers(user, team: team).except("Content-Type")

    expect(response).to have_http_status(:ok)
    expect(JSON.parse(response.body)["signed_id"]).to be_present
  end
end
