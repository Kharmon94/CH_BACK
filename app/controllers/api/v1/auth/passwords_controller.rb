# frozen_string_literal: true

module Api
  module V1
    module Auth
      class PasswordsController < PublicController
        include Api::V1::AuthCredentialParams

        def forgot
          user = User.find_for_authentication(email: auth_email)

          if user && !user.admin?
            user.send_reset_password_instructions
          end

          head :ok
        end

        def reset
          user = User.reset_password_by_token(
            reset_password_token: params[:reset_password_token].to_s,
            password: auth_password,
            password_confirmation: auth_password_confirmation.presence || auth_password
          )

          if user.errors.empty?
            head :ok
          else
            render json: { error: user.errors.full_messages.first || "Could not reset password" },
              status: :unprocessable_entity
          end
        end
      end
    end
  end
end
