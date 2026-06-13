# frozen_string_literal: true

module Api
  module V1
    class BaseController < ProtectedController
      include Api::V1::TeamScoped

      rescue_from ActiveRecord::RecordNotFound, with: :not_found
      rescue_from ArgumentError, with: :unprocessable

      private

      def current_license
        @current_license ||= current_team&.license
      end

      def license_json(team)
        StripeService.sync_subscription(team.license) if team.license&.stripe_subscription_id.present?
        {
          tier: team.license&.tier || "free",
          pro: team.pro?,
          export_count: team.export_count,
          exports_remaining: team.pro? ? nil : [ 1 - team.export_count, 0 ].max
        }
      end

      def forbidden(message)
        render json: { error: message }, status: :forbidden
      end

      def not_found(error)
        render json: { error: error.message }, status: :not_found
      end

      def unprocessable(error)
        render json: { error: error.message }, status: :unprocessable_entity
      end
    end
  end
end
