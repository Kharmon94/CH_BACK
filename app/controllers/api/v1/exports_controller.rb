# frozen_string_literal: true

module Api
  module V1
    class ExportsController < BaseController
      before_action :require_workspace!, only: [ :index, :create ]

      def index
        scope = ExportRecord.joins(linked_database: :workspace)
                            .where(workspaces: { id: current_workspace.id })
                            .order(created_at: :desc)
        render json: scope.limit(100).map { |e| export_json(e) }
      end

      def create
        format = params.require(:format)
        composer_id = params.require(:composer_id)
        linked_database_id = params.require(:linked_database_id)

        linked_db = current_workspace.linked_databases.find(linked_database_id)

        unless ExportRecord::FORMATS.include?(format)
          return render json: { error: "Invalid format" }, status: :unprocessable_entity
        end

        unless ProFeatureGate.allow?(format: format, license_tier: license_tier)
          return forbidden("Agent Clone export requires Pro")
        end

        export = nil
        reserve_quota = false

        if DesktopMode.enabled?
          begin
            Cloud::LicenseClient.reserve_export!(
              team_id: current_team.id,
              token: bearer_token,
              format: format
            )
          rescue ArgumentError => e
            return forbidden(e.message)
          end
        end

        current_team.with_lock do
          export_count = DesktopMode.enabled? ? cloud_export_count : current_team.export_count
          if format == "markdown" && !pro? && export_count >= 1
            return forbidden("Free tier allows 1 markdown export per team")
          end

          cache = ComposerCache.find_by_composer_id!(linked_db.id, composer_id)
          reserve_quota = format == "markdown" && !pro?
          current_team.increment!(:export_count) if reserve_quota && !DesktopMode.enabled?

          export = ExportRecord.create!(
            linked_database_id: linked_db.id,
            composer_id: composer_id,
            composer_name: cache.name,
            format: format,
            status: "queued",
            progress_pct: 0,
            phase: "indexing"
          )
        end

        ExportChatJob.perform_later(export.id, team_id: current_team.id, reserve_quota: reserve_quota)
        render json: export_json(export), status: :created
      end

      def reserve
        format = params.require(:format)

        unless ExportRecord::FORMATS.include?(format)
          return render json: { error: "Invalid format" }, status: :unprocessable_entity
        end

        unless ProFeatureGate.allow?(format: format, license_tier: license_tier)
          return forbidden("Agent Clone export requires Pro")
        end

        current_team.with_lock do
          if format == "markdown" && !pro? && current_team.export_count >= 1
            return forbidden("Free tier allows 1 markdown export per team")
          end

          current_team.increment!(:export_count) if format == "markdown" && !pro?
        end

        render json: { reserved: true, license: license_json(current_team) }
      end

      def show
        export = scoped_exports.find(params[:id])
        render json: export_json(export)
      end

      def download
        export = scoped_exports.find(params[:id])
        unless export.completed? && export.file_path.present? && File.file?(export.file_path)
          return render json: { error: "Export not ready" }, status: :not_found
        end

        unless download_allowed?(export)
          return forbidden("Free tier allows re-download of 1 export only")
        end

        send_file export.file_path,
                  filename: export.output_filename,
                  type: "text/markdown",
                  disposition: "attachment"
      end

      private

      def scoped_exports
        if current_user.admin?
          ExportRecord.all
        else
          ExportRecord.joins(linked_database: { workspace: :team })
                      .where(teams: { id: current_team.id })
        end
      end

      def download_allowed?(export)
        return true if pro?

        first_completed = ExportRecord.joins(linked_database: { workspace: :team })
                                      .where(teams: { id: current_team.id }, status: "completed")
                                      .order(created_at: :asc)
                                      .first
        first_completed&.id == export.id
      end

      def export_json(export)
        {
          id: export.id,
          linked_database_id: export.linked_database_id,
          composer_id: export.composer_id,
          composer_name: export.composer_name,
          format: export.format,
          status: export.status,
          progress_pct: export.progress_pct,
          phase: export.phase,
          session_count: export.session_count,
          error: export.error_message,
          download_url: export.completed? ? download_api_v1_export_url(export) : nil,
          created_at: export.created_at.iso8601
        }
      end
    end
  end
end
