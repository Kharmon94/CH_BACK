# frozen_string_literal: true

module Api
  module V1
    module Admin
      class BaseController < ProtectedController
        before_action :require_admin!
      end
    end
  end
end
