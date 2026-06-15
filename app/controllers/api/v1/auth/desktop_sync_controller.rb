# frozen_string_literal: true

module Api
  module V1
    module Auth
      class DesktopSyncController < ProtectedController
        include Api::V1::UserAuthJson

        def create
          user = Desktop::UserSyncer.call(
            user_payload: user_params,
            teams_payload: teams_params
          )
          render json: { user: user_auth_json(user) }
        rescue ArgumentError => e
          render json: { error: e.message }, status: :unprocessable_entity
        end

        private

        def user_params
          params.require(:user).permit(:id, :email, :role, :name).to_h.symbolize_keys
        end

        def teams_params
          Array(params[:teams]).map do |team|
            team.permit(:id, :name, :slug, license: [ :tier, :pro ]).to_h.deep_symbolize_keys
          end
        end
      end
    end
  end
end
