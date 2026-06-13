# frozen_string_literal: true

module Api
  module V1
    module Auth
      class RegistrationsController < PublicController
        include Api::V1::AuthCredentialParams
        include Api::V1::UserAuthJson

        def create
          email = auth_email
          password = auth_password
          password_confirmation = auth_password_confirmation.presence || password
          name = params[:name].to_s.strip.presence

          user = User.new(
            email: email,
            password: password,
            password_confirmation: password_confirmation,
            name: name,
            role: :user
          )

          if user.save
            TeamProvisioner.call(user, name: name)
            token = JwtService.encode(user.jwt_payload)
            render json: { token: token, user: user_auth_json(user.reload) }, status: :created
          else
            render json: { error: user.errors.full_messages.first || "Could not create account" }, status: :unprocessable_entity
          end
        end
      end
    end
  end
end
