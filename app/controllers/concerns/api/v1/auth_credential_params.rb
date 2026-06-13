# frozen_string_literal: true

module Api
  module V1
    module AuthCredentialParams
      extend ActiveSupport::Concern

      private

      def auth_email
        params[:email].to_s.strip.downcase
      end

      def auth_password
        params[:password].to_s
      end

      def auth_password_confirmation
        params[:password_confirmation].to_s
      end

      def auth_name
        params[:name].to_s.strip.presence
      end

      def admin_context?
        params[:context].to_s == "admin"
      end
    end
  end
end
