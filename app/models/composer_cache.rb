class ComposerCache < ApplicationRecord
  belongs_to :linked_database

  validates :composer_id, presence: true, uniqueness: { scope: :linked_database_id }

  scope :search, ->(query) {
    where("name LIKE ?", "%#{sanitize_sql_like(query)}%") if query.present?
  }
  scope :by_mode, ->(mode) { where(mode: mode) if mode.present? }
  scope :recent, -> { order(updated_at_ms: :desc) }

  def self.find_by_composer_id!(linked_database_id, composer_id)
    find_by!(linked_database_id: linked_database_id, composer_id: composer_id)
  end
end
