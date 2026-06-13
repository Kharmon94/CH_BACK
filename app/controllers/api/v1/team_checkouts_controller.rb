# frozen_string_literal: true

module Api
  module V1
    class TeamCheckoutsController < BaseController
      def create
        authorize! :checkout, current_team

        plan = params.require(:plan)
        unless %w[monthly annual].include?(plan)
          return render json: { error: "Invalid plan" }, status: :unprocessable_entity
        end

        session = StripeService.create_checkout_session(current_user, current_team, plan: plan)
        render json: { url: session.url }
      rescue CanCan::AccessDenied
        forbidden("Only team owners can manage billing")
      rescue KeyError => e
        render json: { error: e.message }, status: :service_unavailable
      rescue Stripe::StripeError => e
        render json: { error: e.message }, status: :unprocessable_entity
      end

      def confirm
        authorize! :checkout, current_team

        session_id = params.require(:session_id)
        StripeService.confirm_checkout_session(current_user, current_team, session_id)
        render json: license_json(current_team.reload)
      rescue CanCan::AccessDenied
        forbidden("Only team owners can manage billing")
      rescue ArgumentError => e
        render json: { error: e.message }, status: :unprocessable_entity
      end
    end
  end
end
