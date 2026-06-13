# frozen_string_literal: true

module Api
  module V1
    class TeamInvitesController < ProtectedController
      before_action :set_team, only: :create

      def create
        authorize! :manage, @team
        invite = @team.team_invites.create!(
          email: params.require(:email).to_s.strip.downcase,
          role: params[:role].presence_in(TeamInvite.roles.keys) || "member",
          invited_by: current_user
        )
        TeamInviteMailer.invite(invite).deliver_later
        render json: invite_json(invite), status: :created
      end

      def accept
        invite = TeamInvite.find_by!(token: params[:token])
        team = invite.team
        invite.accept!(current_user)
        render json: {
          message: "Invite accepted",
          team: {
            id: team.id,
            name: team.name
          }
        }
      rescue ActiveRecord::RecordNotFound
        render json: { error: "Invalid invite" }, status: :not_found
      rescue ArgumentError => e
        render json: { error: e.message }, status: :unprocessable_entity
      end

      private

      def set_team
        @team = Team.find(params[:team_id])
      end

      def invite_json(invite)
        {
          id: invite.id,
          email: invite.email,
          role: invite.role,
          expires_at: invite.expires_at.iso8601
        }
      end
    end
  end
end
