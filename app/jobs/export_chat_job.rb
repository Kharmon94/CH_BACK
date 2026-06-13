class ExportChatJob < ApplicationJob
  queue_as :default

  def perform(export_record_id, team_id: nil, reserve_quota: false)
    export = ExportRecord.find(export_record_id)
    export.update!(status: "running", progress_pct: 0, phase: "indexing", error_message: nil)

    linked_database = export.linked_database
    on_progress = lambda do |pct, phase = nil|
      attrs = { progress_pct: pct }
      attrs[:phase] = phase if phase
      export.update!(attrs)
    end

    result = case export.format
    when "markdown"
      content = Cursor::MarkdownExporter.new(
        linked_database,
        export.composer_id,
        on_progress: ->(pct) { on_progress.call(pct, "fetching_bubbles") }
      ).call
      { content: content, filename: "#{sanitize_name(export.composer_name)}.md" }
    when "agent_clone"
      Cursor::AgentCloneExporter.new(
        linked_database,
        export.composer_id,
        on_progress: ->(pct, phase) { on_progress.call(pct, phase) }
      ).call
    else
      raise ArgumentError, "Unknown format: #{export.format}"
    end

    dir = Rails.root.join("storage/exports")
    FileUtils.mkdir_p(dir)
    file_path = dir.join("#{export.id}_#{result[:filename]}")
    File.write(file_path, result[:content])

    export.update!(
      status: "completed",
      progress_pct: 100,
      phase: "saving",
      file_path: file_path.to_s,
      session_count: result[:session_count] || 1,
      error_message: nil
    )
  rescue StandardError => e
    rollback_quota(team_id, reserve_quota)
    export&.update!(status: "failed", error_message: e.message, progress_pct: export&.progress_pct || 0)
    raise
  end

  private

  def rollback_quota(team_id, reserve_quota)
    return unless reserve_quota && team_id.present?

    team = Team.find_by(id: team_id)
    team&.decrement!(:export_count) if team&.export_count&.positive?
  end

  def sanitize_name(name)
    (name || "export").gsub(/[^\w\s-]/, "").strip.gsub(/\s+/, "_")
  end
end
