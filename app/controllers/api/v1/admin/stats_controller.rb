# frozen_string_literal: true

module Api
  module V1
    module Admin
      class StatsController < Admin::BaseController
        include Api::V1::Admin::LicenseFields

        def show
          teams_count = Team.count
          pro_teams_count = License.where(tier: "pro").count

          render json: {
            users_count: User.count,
            admins_count: User.admin.count,
            teams_count: teams_count,
            pro_teams_count: pro_teams_count,
            free_teams_count: teams_count - pro_teams_count,
            total_exports: Team.sum(:export_count),
            recent_users: User.order(created_at: :desc).limit(5).map { |u| recent_user_json(u) },
            recent_teams: Team.includes(:license).order(created_at: :desc).limit(5).map { |t| recent_team_json(t) }
          }
        end

        private

        def recent_user_json(user)
          {
            id: user.id,
            email: user.email,
            role: user.role,
            created_at: user.created_at.iso8601
          }
        end

        def recent_team_json(team)
          {
            id: team.id,
            name: team.name,
            slug: team.slug,
            license: license_json(team),
            created_at: team.created_at.iso8601
          }
        end
      end
    end
  end
end
