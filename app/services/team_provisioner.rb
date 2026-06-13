# frozen_string_literal: true

class TeamProvisioner
  def self.call(user, name: nil)
    display = name.presence || user.name.presence || user.email&.split("@")&.first&.titleize || "My"
    team = Team.create!(name: "#{display}'s Team")
    TeamMembership.create!(user: user, team: team, role: :owner)
    team.workspaces.create!(name: "Default")
    team.create_license!(tier: "free") unless team.license
    team
  end
end
