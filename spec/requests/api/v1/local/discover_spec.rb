require "rails_helper"

RSpec.describe Api::V1::Local::DiscoverController, type: :controller do
  include RequestAuthHelpers

  routes do
    ActionDispatch::Routing::RouteSet.new.tap do |routes|
      routes.draw do
        namespace :api do
          namespace :v1 do
            get "local/discover", to: "local/discover#show"
          end
        end
      end
    end
  end

  let!(:user) { create_user_with_team.first }
  let!(:team) { user.teams.first }
  let!(:workspace) { team.workspaces.first }

  before do
    request.headers.merge!(auth_headers(user, team: team, workspace: workspace))
  end

  describe "GET #show" do
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

        get :show

        expect(response).to have_http_status(:ok)
        body = JSON.parse(response.body)
        expect(body["found"]).to be(true)
        expect(body["path"]).to eq(path)
      ensure
        ENV["CURSOR_DB_SEARCH_ROOTS"] = original
      end
    end
  end
end
