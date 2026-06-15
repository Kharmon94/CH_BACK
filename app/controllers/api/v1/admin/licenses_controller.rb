# frozen_string_literal: true

module Api
  module V1
    module Admin
      class LicensesController < Admin::BaseController
        include Api::V1::Admin::LicenseFields

        def index
          teams = Team.includes(:license, :team_memberships).order(:name).limit(200)
          teams = apply_tier_filter(teams)

          render json: teams.map { |t| license_row_json(t) }
        end

        private

        def apply_tier_filter(teams)
          case params[:tier]
          when "pro"
            teams.joins(:license).where(licenses: { tier: "pro" })
          when "free"
            teams.left_joins(:license).where("licenses.id IS NULL OR licenses.tier = ?", "free")
          else
            teams
          end
        end
      end
    end
  end
end
