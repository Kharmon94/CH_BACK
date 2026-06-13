# frozen_string_literal: true

class TeamMembership < ApplicationRecord
  belongs_to :user
  belongs_to :team

  enum :role, { owner: "owner", member: "member" }, validate: true

  validates :user_id, uniqueness: { scope: :team_id }
end
