# frozen_string_literal: true

module Api
  module V1
    module Auth
      class MeController < ProtectedController
        include Api::V1::UserAuthJson

        def show
          render json: { user: user_auth_json(current_user) }
        end
      end
    end
  end
end
