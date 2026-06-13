# frozen_string_literal: true

class Team < ApplicationRecord
  has_one :license, dependent: :destroy
  has_many :team_memberships, dependent: :destroy
  has_many :users, through: :team_memberships
  has_many :workspaces, dependent: :destroy
  has_many :team_invites, dependent: :destroy

  validates :name, presence: true
  validates :slug, presence: true, uniqueness: true

  before_validation :assign_slug, on: :create

  def pro?
    license&.pro?
  end

  def owners
    users.joins(:team_memberships).where(team_memberships: { role: :owner })
  end

  private

  def assign_slug
    return if slug.present?

    base = name.to_s.parameterize.presence || "team"
    candidate = base
    n = 2
    while Team.where(slug: candidate).where.not(id: id).exists?
      candidate = "#{base}-#{n}"
      n += 1
    end
    self.slug = candidate
  end
end
