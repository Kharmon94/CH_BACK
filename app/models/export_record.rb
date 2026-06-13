class ExportRecord < ApplicationRecord
  belongs_to :linked_database

  STATUSES = %w[queued running completed failed].freeze
  FORMATS = %w[markdown agent_clone].freeze
  PHASES = %w[indexing fetching_bubbles rendering saving].freeze

  validates :format, inclusion: { in: FORMATS }
  validates :status, inclusion: { in: STATUSES }

  def completed?
    status == "completed"
  end

  def failed?
    status == "failed"
  end

  def output_filename
    return File.basename(file_path) if file_path.present?

    base = (composer_name || "export").gsub(/[^\w\s-]/, "").strip.gsub(/\s+/, "_")
    format == "agent_clone" ? "Agent_Clone_#{base}.md" : "#{base}.md"
  end
end
