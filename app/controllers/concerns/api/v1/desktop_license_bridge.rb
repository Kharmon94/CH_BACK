# frozen_string_literal: true

module Api
  module V1
    module DesktopLicenseBridge
      extend ActiveSupport::Concern

      private

      def cloud_license
        return @cloud_license if defined?(@cloud_license)

        @cloud_license =
          if DesktopMode.enabled?
            Cloud::LicenseClient.fetch(team_id: current_team.id, token: bearer_token)
          end
      end

      def license_tier
        if cloud_license
          cloud_license.tier
        else
          current_team&.license&.tier || "free"
        end
      end

      def pro?
        return true if current_user.admin?

        if cloud_license
          cloud_license.pro
        else
          current_team&.pro?
        end
      end

      def cloud_export_count
        cloud_license&.export_count || current_team.export_count
      end
    end
  end
end
