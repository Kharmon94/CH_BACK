# frozen_string_literal: true

module Api
  module V1
    module Admin
      module LicenseFields
        extend ActiveSupport::Concern

        private

        def license_tier(team)
          team.license&.tier || "free"
        end

        def license_json(team)
          {
            tier: license_tier(team),
            pro: team.pro? == true,
            status: team.license&.status
          }
        end

        def license_row_json(team)
          {
            team_id: team.id,
            team_name: team.name,
            team_slug: team.slug,
            tier: license_tier(team),
            pro: team.pro? == true,
            status: team.license&.status,
            export_count: team.export_count,
            member_count: team.team_memberships.count
          }
        end
      end
    end
  end
end
