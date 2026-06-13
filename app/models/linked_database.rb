# frozen_string_literal: true

class LinkedDatabase < ApplicationRecord
  belongs_to :workspace

  has_many :composer_caches, dependent: :destroy
  has_many :export_records, dependent: :destroy

  validates :path, presence: true, uniqueness: true

  INDEX_STATUSES = %w[idle indexing completed failed].freeze

  def indexing?
    index_status == "indexing"
  end

  def team
    workspace.team
  end
end
