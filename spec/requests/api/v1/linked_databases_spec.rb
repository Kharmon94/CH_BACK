require "rails_helper"

RSpec.describe "Api::V1::LinkedDatabases", type: :request do
  let(:db_path) { ENV.fetch("CURSOR_TEST_DB", "/home/vgxd/Projects/Production Projects/ChatHistory/state.db") }
  let!(:user) { create_user_with_team.first }
  let!(:team) { user.teams.first }
  let!(:workspace) { team.workspaces.first }
  let!(:request_headers) { auth_headers(user, team: team, workspace: workspace) }

  describe "POST /api/v1/linked_databases/locate" do
    it "returns a matching path from search roots" do
      Dir.mktmpdir do |dir|
        path = File.join(dir, "state.vscdb")
        File.write(path, "x" * 64)

        original = ENV["CURSOR_DB_SEARCH_ROOTS"]
        ENV["CURSOR_DB_SEARCH_ROOTS"] = dir
        post "/api/v1/linked_databases/locate",
          params: { filename: "state.vscdb", byte_size: 64 },
          headers: request_headers,
          as: :json

        expect(response).to have_http_status(:ok)
        body = JSON.parse(response.body)
        expect(body["path"]).to eq(path)
      ensure
        ENV["CURSOR_DB_SEARCH_ROOTS"] = original
      end
    end
  end

  describe "POST /api/v1/linked_databases" do
    it "rejects invalid path" do
      post "/api/v1/linked_databases", params: { path: "/tmp/nonexistent.db" }, headers: request_headers, as: :json
      expect(response).to have_http_status(:unprocessable_entity)
    end

    it "links a valid database" do
      skip "Test DB not available" unless File.file?(db_path)

      post "/api/v1/linked_databases", params: { path: db_path }, headers: request_headers, as: :json
      expect(response).to have_http_status(:created)
      body = JSON.parse(response.body)
      expect(body["path"]).to eq(db_path)
      expect(body["workspace_id"]).to eq(workspace.id)
      expect(body["index_status"]).to be_present
    end
  end
end
