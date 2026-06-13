# frozen_string_literal: true

module Api
  module V1
    module Auth
      class SessionsController < PublicController
        include Api::V1::AuthCredentialParams
        include Api::V1::UserAuthJson

        def create
          email = auth_email
          password = auth_password
          user = User.find_for_authentication(email: email)

          if user&.valid_password?(password)
            if user.admin?
              render json: { error: "Use admin login for this account" }, status: :forbidden
              return
            end

            token = JwtService.encode(user.jwt_payload)
            render json: { token: token, user: user_auth_json(user) }
          else
            render json: { error: "Invalid email or password" }, status: :unauthorized
          end
        end
      end
    end
  end
end
