# frozen_string_literal: true

module Api
  module V1
    module TeamScoped
      extend ActiveSupport::Concern
      include Api::V1::DesktopLicenseBridge

      included do
        before_action :set_current_team!
      end

      attr_reader :current_team, :current_workspace

      private

      def set_current_team!
        team_id = request.headers["X-Team-Id"].presence || params[:team_id]
        if team_id.blank?
          render json: { error: "X-Team-Id header required" }, status: :bad_request
          return
        end

        @current_team = Team.find(team_id)
        if current_user.admin?
          return
        end

        unless current_user.member_of?(@current_team)
          render json: { error: "Not a member of this team" }, status: :forbidden
          nil
        end
      end

      def set_current_workspace!
        workspace_id = request.headers["X-Workspace-Id"].presence || params[:workspace_id]
        return if workspace_id.blank?

        @current_workspace = @current_team.workspaces.find(workspace_id)
        if current_user.admin?
          return
        end

        authorize! :read, @current_workspace
      end

      def require_workspace!
        set_current_workspace!
        return if performed?

        if @current_workspace.blank?
          render json: { error: "X-Workspace-Id header required" }, status: :bad_request
        end
      end
    end
  end
end
