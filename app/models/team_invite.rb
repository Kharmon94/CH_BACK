# frozen_string_literal: true

class TeamInvite < ApplicationRecord
  belongs_to :team
  belongs_to :invited_by, class_name: "User", optional: true
  belongs_to :invited_by, class_name: "User", optional: true

  enum :role, { owner: "owner", member: "member" }, validate: true

  validates :email, presence: true
  validates :token, presence: true, uniqueness: true
  validates :expires_at, presence: true

  before_validation :normalize_email
  before_validation :assign_token, on: :create
  before_validation :assign_expiry, on: :create

  scope :pending, -> { where(accepted_at: nil).where("expires_at > ?", Time.current) }

  def expired?
    expires_at <= Time.current
  end

  def accepted?
    accepted_at.present?
  end

  def accept!(user)
    raise ArgumentError, "Invite expired" if expired?
    raise ArgumentError, "Invite already accepted" if accepted?
    raise ArgumentError, "Email mismatch" unless user.email == email

    team.team_memberships.find_or_create_by!(user: user) do |membership|
      membership.role = role
    end
    update!(accepted_at: Time.current)
  end

  private

  def normalize_email
    self.email = email.to_s.strip.downcase
  end

  def assign_token
    self.token ||= SecureRandom.urlsafe_base64(32)
  end

  def assign_expiry
    self.expires_at ||= 7.days.from_now
  end
end
