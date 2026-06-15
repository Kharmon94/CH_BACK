# frozen_string_literal: true

module Api
  module V1
    module Admin
      class UsersController < Admin::BaseController
        def index
          users = User.order(:email).limit(200)
          render json: users.map { |u| user_json(u) }
        end

        def show
          user = User.find(params[:id])
          render json: user_json(user, include_teams: true)
        end

        def update
          user = User.find(params[:id])

          if params[:role].present?
            role = params[:role].to_s
            unless User.roles.key?(role)
              return render json: { error: "Invalid role" }, status: :unprocessable_entity
            end

            if role == "user" && user.admin?
              if User.admin.count == 1
                return render json: { error: "Cannot demote the last admin" }, status: :unprocessable_entity
              end

              if current_user.id == user.id
                return render json: { error: "Cannot demote yourself" }, status: :unprocessable_entity
              end
            end
          end

          user.update!(user_params)
          render json: user_json(user, include_teams: true)
        end

        private

        def user_params
          params.permit(:name, :role)
        end

        def user_json(user, include_teams: false)
          data = {
            id: user.id,
            email: user.email,
            name: user.name,
            role: user.role,
            created_at: user.created_at.iso8601
          }
          if include_teams
            data[:teams] = user.teams.map { |t| { id: t.id, name: t.name, slug: t.slug } }
          end
          data
        end
      end
    end
  end
end
