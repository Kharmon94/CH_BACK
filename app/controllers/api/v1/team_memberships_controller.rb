# frozen_string_literal: true

module Api
  module V1
    class TeamMembershipsController < ProtectedController
      before_action :set_team!

      def index
        authorize! :read, @team
        memberships = @team.team_memberships.includes(:user)
        render json: memberships.map { |m| membership_json(m) }
      end

      def create
        membership = @team.team_memberships.build
        authorize! :create, membership

        email = params.require(:email).to_s.strip.downcase
        role = params[:role].presence_in(%w[owner member]) || "member"

        if @team.team_memberships.joins(:user).exists?(users: { email: email })
          return render json: { error: "User is already a member" }, status: :unprocessable_entity
        end

        invite = @team.team_invites.create!(email: email, role: role, invited_by_id: current_user.id)
        TeamInviteMailer.invite(invite).deliver_later

        render json: { message: "Invite sent", invite: invite_json(invite) }, status: :created
      end

      def destroy
        membership = @team.team_memberships.find(params[:id])
        authorize! :destroy, membership

        if membership.owner? && @team.team_memberships.owner.count <= 1
          return render json: { error: "Cannot remove the only owner" }, status: :unprocessable_entity
        end

        membership.destroy!
        head :no_content
      end

      private

      def set_team!
        @team = Team.find(params[:team_id])
      end

      def membership_json(membership)
        {
          id: membership.id,
          user_id: membership.user_id,
          email: membership.user.email,
          name: membership.user.name,
          role: membership.role
        }
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
