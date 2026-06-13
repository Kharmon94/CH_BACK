# frozen_string_literal: true

class Workspace < ApplicationRecord
  belongs_to :team
  has_many :linked_databases, dependent: :destroy

  validates :name, presence: true
  validates :slug, presence: true, uniqueness: { scope: :team_id }

  before_validation :assign_slug, on: :create

  private

  def assign_slug
    return if slug.present?

    base = name.to_s.parameterize.presence || "workspace"
    candidate = base
    n = 2
    while team&.workspaces&.where(slug: candidate)&.where&.not(id: id)&.exists?
      candidate = "#{base}-#{n}"
      n += 1
    end
    self.slug = candidate
  end
end
