require "rails_helper"

RSpec.describe "Api::V1::Composers", type: :request do
  let(:db_path) { ENV.fetch("CURSOR_TEST_DB", "/home/vgxd/Projects/Production Projects/ChatHistory/state.db") }
  let!(:user) { create_user_with_team.first }
  let!(:team) { user.teams.first }
  let!(:workspace) { team.workspaces.first }
  let!(:request_headers) { auth_headers(user, team: team, workspace: workspace) }

  before do
    skip "Test DB not available" unless File.file?(db_path)

    @linked = workspace.linked_databases.find_or_create_by!(path: db_path) do |db|
      db.index_status = "indexing"
    end
    Cursor::ComposerIndexer.new(@linked).call unless ComposerCache.where(linked_database_id: @linked.id).exists?
  end

  describe "GET /api/v1/composers" do
    it "returns team workflow composers" do
      get "/api/v1/composers", params: { linked_database_id: @linked.id, q: "team workflow" }, headers: request_headers
      expect(response).to have_http_status(:ok)
      body = JSON.parse(response.body)
      expect(body["data"].length).to eq(4)
    end
  end
end
