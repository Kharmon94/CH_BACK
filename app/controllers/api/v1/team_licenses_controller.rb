# frozen_string_literal: true

module Api
  module V1
    class TeamLicensesController < ProtectedController
      before_action :set_team

      def show
        authorize! :read, @team
        StripeService.sync_subscription(@team.license) if @team.license&.stripe_subscription_id.present?
        render json: license_json(@team.reload)
      end

      private

      def set_team
        @team = Team.find(params[:team_id])
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
