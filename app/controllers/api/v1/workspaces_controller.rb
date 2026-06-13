# frozen_string_literal: true

module Api
  module V1
    class WorkspacesController < ProtectedController
      before_action :set_team!

      def index
        authorize! :read, @team
        workspaces = @team.workspaces.order(:name)
        render json: workspaces.map { |w| workspace_json(w) }
      end

      def show
        workspace = @team.workspaces.find(params[:id])
        authorize! :read, workspace
        render json: workspace_json(workspace)
      end

      def create
        workspace = @team.workspaces.build(workspace_params)
        authorize! :create, workspace
        workspace.save!
        render json: workspace_json(workspace), status: :created
      end

      def update
        workspace = @team.workspaces.find(params[:id])
        authorize! :update, workspace
        workspace.update!(workspace_params)
        render json: workspace_json(workspace)
      end

      def destroy
        workspace = @team.workspaces.find(params[:id])
        authorize! :destroy, workspace

        if @team.workspaces.count <= 1
          return render json: { error: "Cannot delete the only workspace" }, status: :unprocessable_entity
        end

        workspace.destroy!
        head :no_content
      end

      private

      def set_team!
        @team = Team.find(params[:team_id])
        return if current_user.admin?
        return if current_user.member_of?(@team)

        render json: { error: "Not a member of this team" }, status: :forbidden
      end

      def workspace_params
        params.permit(:name, :root_path)
      end

      def workspace_json(workspace)
        {
          id: workspace.id,
          team_id: workspace.team_id,
          name: workspace.name,
          slug: workspace.slug,
          root_path: workspace.root_path,
          linked_database_count: workspace.linked_databases.count
        }
      end
    end
  end
end
