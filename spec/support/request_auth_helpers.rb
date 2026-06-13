# frozen_string_literal: true

module RequestAuthHelpers
  def json_headers(extra = {})
    { "Accept" => "application/json" }.merge(extra)
  end

  def auth_headers(user, team: nil, workspace: nil)
    token = JwtService.encode(user.jwt_payload)
    headers = json_headers("Authorization" => "Bearer #{token}")
    headers["X-Team-Id"] = team.id.to_s if team
    headers["X-Workspace-Id"] = workspace.id.to_s if workspace
    headers
  end

  def create_user_with_team(email: "user@example.com", password: "password123", role: :user)
    user = User.create!(
      email: email,
      password: password,
      password_confirmation: password,
      role: role,
      name: "Test User"
    )
    team = TeamProvisioner.call(user)
    workspace = team.workspaces.first
    [ user, team, workspace ]
  end

  def create_admin!(email: "admin@cursorhelp.com", password: "password123")
    User.create!(
      email: email,
      password: password,
      password_confirmation: password,
      role: :admin
    )
  end
end

RSpec.configure do |config|
  config.include RequestAuthHelpers, type: :request
end
