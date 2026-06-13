# frozen_string_literal: true

module Api
  module V1
    class ProtectedController < ApplicationController
      include Api::V1::Authorizable

      before_action :authenticate_user!
    end
  end
end
