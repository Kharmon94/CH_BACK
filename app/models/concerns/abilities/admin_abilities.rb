# frozen_string_literal: true

module Abilities
  module AdminAbilities
    def grant_admin_abilities(_user)
      can :access, :admin
      can :manage, :all
      can :create, :image_upload
    end
  end
end
