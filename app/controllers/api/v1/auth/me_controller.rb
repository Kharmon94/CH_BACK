# frozen_string_literal: true

module Api
  module V1
    module Auth
      class MeController < ProtectedController
        include ActiveStorageAttachable
        include Api::V1::UserAuthJson

        def show
          render json: { user: user_auth_json(current_user) }
        end

        def update
          current_user.name = params[:name].to_s.strip if params.key?(:name)
          attach_blob!(current_user.avatar, params[:avatar_signed_id])

          if current_user.save
            render json: { user: user_auth_json(current_user.reload) }
          else
            render json: { error: current_user.errors.full_messages.first || "Could not update profile" },
              status: :unprocessable_entity
          end
        rescue ActiveRecord::RecordInvalid => e
          render json: { error: e.message }, status: :unprocessable_entity
        end
      end
    end
  end
end
