# frozen_string_literal: true

module Desktop
  class UserSyncer
    def self.call(user_payload:, teams_payload:)
      new(user_payload:, teams_payload:).call
    end

    def initialize(user_payload:, teams_payload:)
      @user_payload = user_payload
      @teams_payload = teams_payload
    end

    def call
      raise ArgumentError, "User id is required" if user_payload[:id].blank?
      raise ArgumentError, "User email is required" if user_payload[:email].blank?

      user = nil
      ActiveRecord::Base.transaction do
        user = sync_user
        sync_teams(user)
      end
      user.reload
    end

    private

    attr_reader :user_payload, :teams_payload

    def sync_user
      user = User.find_by(id: user_payload[:id]) || User.new
      user.id = user_payload[:id]
      user.assign_attributes(
        email: user_payload[:email],
        role: user_payload[:role].presence || "user",
        name: user_payload[:name]
      )
      user.password = SecureRandom.hex(32) if user.new_record? || user.encrypted_password.blank?
      user.save!
      user
    end

    def sync_teams(user)
      teams_payload.each do |team_data|
        team = Team.find_by(id: team_data[:id]) || Team.new
        team.id = team_data[:id]
        team.assign_attributes(
          name: team_data[:name].presence || "Team",
          slug: team_data[:slug].presence || "team-#{team_data[:id]}"
        )
        team.save!

        membership = TeamMembership.find_or_initialize_by(user: user, team: team)
        membership.role ||= :owner
        membership.save!

        sync_license(team, team_data[:license])
        ensure_default_workspace(team)
      end
    end

    def sync_license(team, license_data)
      return if license_data.blank?

      license = team.license || team.build_license
      license.tier = license_data[:tier].presence || "free"
      license.status = license.tier == "pro" ? "active" : license.status
      license.save!
    end

    def ensure_default_workspace(team)
      return if team.workspaces.exists?

      team.workspaces.create!(name: "Default")
    end
  end
end
