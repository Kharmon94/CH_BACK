# frozen_string_literal: true

module Api
  module V1
    module Auth
      class ValidateController < ProtectedController
        def show
          render json: {
            valid: true,
            user: {
              id: current_user.id,
              email: current_user.email,
              role: current_user.role,
              name: current_user.name
            }
          }
        end
      end
    end
  end
end
