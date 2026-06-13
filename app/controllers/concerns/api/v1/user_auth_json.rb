# frozen_string_literal: true

module Api
  module V1
    module UserAuthJson
      extend ActiveSupport::Concern

      private

      def user_auth_json(user)
        teams = user.teams.includes(:license).map { |team| team_summary_json(team, user) }
        {
          id: user.id,
          email: user.email,
          role: user.role,
          name: user.name,
          avatar_url: BlobUrl.for(user.avatar),
          teams: teams
        }
      end

      def team_summary_json(team, user)
        membership = user.team_memberships.find { |m| m.team_id == team.id }
        {
          id: team.id,
          name: team.name,
          slug: team.slug,
          membership_role: membership&.role,
          license: {
            tier: team.license&.tier || "free",
            pro: team.pro?
          }
        }
      end
    end
  end
end
