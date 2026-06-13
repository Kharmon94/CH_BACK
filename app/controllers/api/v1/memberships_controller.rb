# frozen_string_literal: true

module Api
  module V1
    class MembershipsController < ProtectedController
      before_action :set_team

      def index
        authorize! :read, @team
        render json: @team.team_memberships.includes(:user).map { |m| membership_json(m) }
      end

      def create
        authorize! :manage, @team
        user = User.find_by!(email: params.require(:email).to_s.strip.downcase)
        role = params[:role].presence_in(TeamMembership.roles.keys) || "member"
        membership = @team.team_memberships.find_or_initialize_by(user: user)
        membership.role = role
        membership.save!
        render json: membership_json(membership), status: :created
      rescue ActiveRecord::RecordNotFound
        render json: { error: "User not found" }, status: :not_found
      end

      def destroy
        authorize! :manage, @team
        membership = @team.team_memberships.find_by!(user_id: params[:id])
        if membership.owner? && @team.team_memberships.where(role: :owner).count <= 1
          return render json: { error: "Cannot remove the last owner" }, status: :unprocessable_entity
        end
        membership.destroy!
        head :no_content
      end

      private

      def set_team
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
    end
  end
end
