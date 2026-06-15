require "rails_helper"

RSpec.describe "Api::V1::Exports", type: :request do
  let(:db_path) { CursorTestDb.path }
  let!(:user) { create_user_with_team.first }
  let!(:team) { user.teams.first }
  let!(:workspace) { team.workspaces.first }
  let!(:request_headers) { auth_headers(user, team: team, workspace: workspace) }

  before do
    skip "Test DB not available" unless db_path

    @linked = workspace.linked_databases.find_or_create_by!(path: db_path) do |db|
      db.index_status = "indexing"
    end
    Cursor::ComposerIndexer.new(@linked).call unless ComposerCache.where(linked_database_id: @linked.id).exists?
    @composer = ComposerCache.where(linked_database_id: @linked.id)
                             .where("name LIKE ?", "%team workflow%")
                             .find { |c| c.mode == "agent" && c.status == "completed" }
  end

  describe "POST /api/v1/exports (Pro)" do
    before do
      team.license.update!(tier: "pro", status: "active")
    end

    it "creates markdown export" do
      post "/api/v1/exports",
        params: {
          linked_database_id: @linked.id,
          composer_id: @composer.composer_id,
          format: "markdown"
        },
        headers: request_headers,
        as: :json
      expect(response).to have_http_status(:created)
      export_id = JSON.parse(response.body)["id"]

      perform_enqueued_jobs
      get "/api/v1/exports/#{export_id}", headers: auth_headers(user, team: team)
      body = JSON.parse(response.body)
      expect(body["status"]).to eq("completed")

      get "/api/v1/exports/#{export_id}/download", headers: auth_headers(user, team: team)
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Session")
    end

    it "creates agent clone export with expected structure" do
      post "/api/v1/exports",
        params: {
          linked_database_id: @linked.id,
          composer_id: @composer.composer_id,
          format: "agent_clone"
        },
        headers: request_headers,
        as: :json
      export_id = JSON.parse(response.body)["id"]
      perform_enqueued_jobs

      get "/api/v1/exports/#{export_id}/download", headers: auth_headers(user, team: team)
      expect(response).to have_http_status(:ok)
      content = response.body
      expect(content).not_to include("# Agent Handoff")
      expect(content).to start_with("## Start here")
      expect(content).to include("## Pick up here")
      expect(content).to include("retry")
      expect(content).to include("**PRIMARY**")
      expect(content).to include("## Sessions in this handoff")
    end
  end

  describe "POST /api/v1/exports (Free)" do
    it "rejects agent clone" do
      post "/api/v1/exports",
        params: {
          linked_database_id: @linked.id,
          composer_id: @composer.composer_id,
          format: "agent_clone"
        },
        headers: request_headers,
        as: :json
      expect(response).to have_http_status(:forbidden)
      expect(JSON.parse(response.body)["error"]).to include("Pro")
    end

    it "allows one markdown export then rejects second" do
      params = {
        linked_database_id: @linked.id,
        composer_id: @composer.composer_id,
        format: "markdown"
      }

      post "/api/v1/exports", params: params, headers: request_headers, as: :json
      expect(response).to have_http_status(:created)
      perform_enqueued_jobs

      post "/api/v1/exports", params: params, headers: request_headers, as: :json
      expect(response).to have_http_status(:forbidden)
      expect(JSON.parse(response.body)["error"]).to include("1 markdown export")
    end

    it "allows re-download of only the first completed export" do
      other = ComposerCache.where(linked_database_id: @linked.id).where.not(composer_id: @composer.composer_id).first

      post "/api/v1/exports", params: {
        linked_database_id: @linked.id,
        composer_id: @composer.composer_id,
        format: "markdown"
      }, headers: request_headers, as: :json
      first_id = JSON.parse(response.body)["id"]
      perform_enqueued_jobs

      team.license.update!(tier: "pro", status: "active")
      post "/api/v1/exports", params: {
        linked_database_id: @linked.id,
        composer_id: other.composer_id,
        format: "markdown"
      }, headers: request_headers, as: :json
      second_id = JSON.parse(response.body)["id"]
      perform_enqueued_jobs

      team.license.update!(tier: "free", status: nil, stripe_subscription_id: nil)

      get "/api/v1/exports/#{first_id}/download", headers: auth_headers(user, team: team)
      expect(response).to have_http_status(:ok)

      get "/api/v1/exports/#{second_id}/download", headers: auth_headers(user, team: team)
      expect(response).to have_http_status(:forbidden)
    end
  end
end
