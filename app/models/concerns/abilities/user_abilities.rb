# frozen_string_literal: true

module Abilities
  module UserAbilities
    def grant_user_abilities(user)
      team_ids = user.team_memberships.pluck(:team_id)
      owner_team_ids = user.team_memberships.where(role: :owner).pluck(:team_id)

      can :create, Team
      can :read, Team, id: team_ids
      can :manage, Team, id: owner_team_ids
      can :read, License, team_id: team_ids

      can :read, Workspace, team_id: team_ids
      can :create, Workspace, team_id: team_ids
      can :manage, Workspace, team_id: owner_team_ids
      can :manage, TeamMembership, team_id: owner_team_ids
      can :create, TeamMembership, team_id: owner_team_ids
      can :manage, TeamInvite, team_id: owner_team_ids

      can :manage, LinkedDatabase, workspace: { team_id: team_ids }
      can :manage, ExportRecord, linked_database: { workspace: { team_id: team_ids } }

      can :create, :image_upload
      can :checkout, Team, id: owner_team_ids
    end
  end
end
