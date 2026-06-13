# frozen_string_literal: true

module Api
  module V1
    module Admin
      class UsersController < BaseController
        def index
          users = User.order(:email).limit(200)
          render json: users.map { |u| user_json(u) }
        end

        def show
          user = User.find(params[:id])
          render json: user_json(user, include_teams: true)
        end

        private

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
