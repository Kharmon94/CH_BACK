# frozen_string_literal: true

module Api
  module V1
    module Authorizable
      extend ActiveSupport::Concern

      private

      def require_admin!
        authorize! :access, :admin
      end
    end
  end
end
