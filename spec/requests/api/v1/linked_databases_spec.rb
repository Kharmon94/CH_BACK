require "rails_helper"

RSpec.describe "Api::V1::LinkedDatabases", type: :request do
  let(:db_path) { CursorTestDb.path }
  let!(:user) { create_user_with_team.first }
  let!(:team) { user.teams.first }
  let!(:workspace) { team.workspaces.first }
  let!(:request_headers) { auth_headers(user, team: team, workspace: workspace) }

  describe "GET /api/v1/linked_databases/discover" do
    it "returns discovery payload" do
      Dir.mktmpdir do |dir|
        path = File.join(dir, "state.vscdb")
        File.write(path, "x" * 64)

        original = ENV["CURSOR_DB_SEARCH_ROOTS"]
        ENV["CURSOR_DB_SEARCH_ROOTS"] = dir
        allow_any_instance_of(Cursor::DatabaseDiscoverer).to receive(:windows_paths).and_return([])
        allow_any_instance_of(Cursor::DatabaseDiscoverer).to receive(:macos_paths).and_return([])
        allow_any_instance_of(Cursor::DatabaseDiscoverer).to receive(:linux_paths).and_return([])
        allow_any_instance_of(Cursor::DatabaseDiscoverer).to receive(:wsl_paths).and_return([])

        get "/api/v1/linked_databases/discover", headers: request_headers

        expect(response).to have_http_status(:ok)
        body = JSON.parse(response.body)
        expect(body["found"]).to be(true)
        expect(body["path"]).to eq(path)
      ensure
        ENV["CURSOR_DB_SEARCH_ROOTS"] = original
      end
    end
  end

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

    it "links state.vscdb the same as legacy state.db copies" do
      skip "Test DB not available" unless db_path

      expect(%w[.vscdb .db]).to include(File.extname(db_path))
      expect(Cursor::DatabaseValidator.validate!(db_path)).to be true

      post "/api/v1/linked_databases", params: { path: db_path }, headers: request_headers, as: :json
      expect(response).to have_http_status(:created)
      body = JSON.parse(response.body)
      expect(body["path"]).to eq(db_path)
      expect(body["workspace_id"]).to eq(workspace.id)
      expect(body["index_status"]).to be_present
    end
  end
end
