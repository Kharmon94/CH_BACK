# frozen_string_literal: true

module Api
  module V1
    class LicensesController < BaseController
      def show
        StripeService.sync_subscription(current_team.license) if current_team.license&.stripe_subscription_id.present?
        render json: license_json(current_team)
      end
    end
  end
end
