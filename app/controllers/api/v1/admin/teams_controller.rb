# frozen_string_literal: true

module Api
  module V1
    module Admin
      class TeamsController < Admin::BaseController
        include Api::V1::Admin::LicenseFields
        def index
          teams = Team.includes(:license, :team_memberships).order(:name).limit(200)
          render json: teams.map { |t| team_json(t) }
        end

        def show
          team = Team.includes(:license, :team_memberships, :workspaces).find(params[:id])
          render json: team_json(team, detailed: true)
        end

        def update
          team = Team.find(params[:id])
          if params[:license_tier].present?
            tier = params[:license_tier]
            unless License::TIERS.include?(tier)
              return render json: { error: "Invalid tier" }, status: :unprocessable_entity
            end

            license = team.license || team.create_license!(tier: "free")
            license.update!(tier: tier, status: tier == "pro" ? "active" : nil)
          end

          team.update!(team_params) if team_params.present?
          render json: team_json(team.reload, detailed: true)
        end

        private

        def team_params
          params.permit(:name)
        end

        def team_json(team, detailed: false)
          data = {
            id: team.id,
            name: team.name,
            slug: team.slug,
            created_at: team.created_at.iso8601,
            export_count: team.export_count,
            member_count: team.team_memberships.count,
            license: license_json(team)
          }
          if detailed
            data[:workspaces] = team.workspaces.map { |w| { id: w.id, name: w.name, slug: w.slug } }
            data[:members] = team.team_memberships.includes(:user).map do |m|
              { id: m.id, email: m.user.email, role: m.role }
            end
          end
          data
        end
      end
    end
  end
end
