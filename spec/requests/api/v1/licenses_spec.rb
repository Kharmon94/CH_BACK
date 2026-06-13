require "rails_helper"

RSpec.describe "Api::V1::Licenses", type: :request do
  let!(:user) { create_user_with_team.first }
  let!(:team) { user.teams.first }
  let!(:request_headers) { auth_headers(user, team: team) }

  describe "GET /api/v1/license" do
    it "returns tier and export quota for team" do
      get "/api/v1/license", headers: request_headers
      expect(response).to have_http_status(:ok)
      body = JSON.parse(response.body)
      expect(body["tier"]).to eq("free")
      expect(body["pro"]).to be false
      expect(body["export_count"]).to eq(0)
      expect(body["exports_remaining"]).to eq(1)
    end

    it "requires authentication" do
      get "/api/v1/license", headers: json_headers("X-Team-Id" => team.id.to_s)
      expect(response).to have_http_status(:unauthorized)
    end

    it "requires X-Team-Id header" do
      get "/api/v1/license", headers: auth_headers(user)
      expect(response).to have_http_status(:bad_request)
    end
  end
end
