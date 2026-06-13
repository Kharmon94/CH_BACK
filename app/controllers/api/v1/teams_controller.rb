# frozen_string_literal: true

module Api
  module V1
    class TeamsController < ProtectedController
      include Api::V1::UserAuthJson

      def index
        teams = current_user.admin? ? Team.order(:name) : current_user.teams.includes(:license)
        render json: teams.map { |team| team_detail_json(team) }
      end

      def show
        team = Team.find(params[:id])
        authorize! :read, team
        render json: team_detail_json(team)
      end

      def create
        team = Team.new(team_params)
        authorize! :create, Team

        ActiveRecord::Base.transaction do
          team.save!
          TeamMembership.create!(user: current_user, team: team, role: :owner)
          team.workspaces.create!(name: "Default")
          team.create_license!(tier: "free")
        end

        render json: team_detail_json(team), status: :created
      end

      def update
        team = Team.find(params[:id])
        authorize! :update, team
        team.update!(team_params)
        render json: team_detail_json(team)
      end

      private

      def team_params
        params.permit(:name)
      end

      def team_detail_json(team)
        membership = current_user.team_memberships.find { |m| m.team_id == team.id } unless current_user.admin?
        {
          id: team.id,
          name: team.name,
          slug: team.slug,
          export_count: team.export_count,
          membership_role: membership&.role,
          license: license_json(team),
          member_count: team.team_memberships.count,
          workspace_count: team.workspaces.count
        }
      end

      def license_json(team)
        {
          tier: team.license&.tier || "free",
          pro: team.pro?,
          export_count: team.export_count,
          exports_remaining: team.pro? ? nil : [ 1 - team.export_count, 0 ].max
        }
      end
    end
  end
end
