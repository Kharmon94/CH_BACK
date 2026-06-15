# frozen_string_literal: true

module Api
  module V1
    class LinkedDatabasesController < BaseController
      before_action :require_workspace!

      def index
        scope = current_workspace.linked_databases.order(created_at: :desc)
        render json: scope.map { |db| linked_database_json(db) }
      end

      def locate
        path = Cursor::DatabaseLocator.locate(
          filename: params.require(:filename),
          byte_size: params.require(:byte_size),
          last_modified_ms: params[:last_modified_ms]
        )
        render json: { path: path }
      rescue ArgumentError => e
        render json: { error: e.message }, status: :unprocessable_entity
      end

      def create
        path = params.require(:path).to_s.strip
        Cursor::DatabaseValidator.validate!(path)

        linked_database = current_workspace.linked_databases.find_or_initialize_by(path: path)
        linked_database.save!
        IndexComposersJob.perform_later(linked_database.id)

        render json: linked_database_json(linked_database), status: :created
      rescue ArgumentError => e
        render json: { error: e.message }, status: :unprocessable_entity
      end

      def destroy
        linked_database = scoped_linked_databases.find(params[:id])
        authorize! :destroy, linked_database
        linked_database.destroy!
        head :no_content
      end

      def refresh
        linked_database = scoped_linked_databases.find(params[:id])
        authorize! :update, linked_database
        linked_database.update!(index_status: "indexing")
        IndexComposersJob.perform_later(linked_database.id)
        render json: linked_database_json(linked_database)
      end

      private

      def scoped_linked_databases
        LinkedDatabase.joins(:workspace).where(workspaces: { team_id: current_team.id })
      end

      def linked_database_json(db)
        {
          id: db.id,
          workspace_id: db.workspace_id,
          path: db.path,
          composer_count: db.composer_count,
          last_indexed_at: db.last_indexed_at,
          index_status: db.index_status,
          index_error: db.index_error
        }
      end
    end
  end
end
