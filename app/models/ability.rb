# frozen_string_literal: true

class Ability
  include CanCan::Ability
  include Abilities::AdminAbilities
  include Abilities::UserAbilities

  def initialize(user)
    return if user.blank?

    if user.admin?
      grant_admin_abilities(user)
    else
      grant_user_abilities(user)
    end
  end
end
