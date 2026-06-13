# frozen_string_literal: true

class User < ApplicationRecord
  devise :database_authenticatable, :recoverable, :validatable

  has_many :team_memberships, dependent: :destroy
  has_many :teams, through: :team_memberships
  has_one_attached :avatar

  enum :role, { admin: 0, user: 1 }, validate: true

  before_validation :normalize_email

  validates :name, length: { maximum: 100 }, allow_blank: true

  def password_required?
    super && provider.blank?
  end

  def jwt_payload
    {
      sub: id,
      email: email,
      role: role,
      name: name
    }
  end

  def team_owner?(team)
    team_memberships.exists?(team_id: team.id, role: :owner)
  end

  def member_of?(team)
    team_memberships.exists?(team_id: team.id)
  end

  private

  def normalize_email
    self.email = email.to_s.strip.downcase
  end
end
