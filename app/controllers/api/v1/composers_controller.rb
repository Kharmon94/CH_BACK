module Api
  module V1
    class ComposersController < BaseController
      def index
        linked_database = find_scoped_linked_database!
        scope = ComposerCache.where(linked_database_id: linked_database.id)
        scope = scope.search(params[:q]) if params[:q].present?
        scope = scope.by_mode(params[:mode]) if params[:mode].present?

        page = [ params[:page].to_i, 1 ].max
        per_page = [ [ params[:per_page].to_i, 1 ].max, 100 ].min
        per_page = 50 if params[:per_page].blank?

        total = scope.count
        records = scope.recent.offset((page - 1) * per_page).limit(per_page)

        render json: {
          data: records.map { |c| composer_json(c) },
          meta: { total: total, page: page, per_page: per_page }
        }
      end

      def show
        linked_database_id = params.require(:linked_database_id)
        find_scoped_linked_database!(linked_database_id)

        cache = ComposerCache.find_by_composer_id!(linked_database_id, params[:id])
        group = Cursor::ComposerGroup.new(cache.linked_database, cache.composer_id)
        primary_id = group.primary_composer_id

        render json: composer_json(cache).merge(
          same_name_session_count: group.session_count,
          primary_composer_id: primary_id,
          is_primary: cache.composer_id == primary_id
        )
      end

      def search
        index
      end

      private

      def find_scoped_linked_database!(id = params.require(:linked_database_id))
        LinkedDatabase.joins(:workspace).where(workspaces: { team_id: current_team.id }).find(id)
      end

      def composer_json(cache)
        {
          id: cache.composer_id,
          linked_database_id: cache.linked_database_id,
          name: cache.name,
          status: cache.status,
          mode: cache.mode,
          message_count: cache.message_count,
          created_at_ms: cache.created_at_ms,
          updated_at_ms: cache.updated_at_ms,
          updated_at: cache.updated_at_ms ? Time.at(cache.updated_at_ms / 1000.0).utc.iso8601 : nil
        }
      end
    end
  end
end
