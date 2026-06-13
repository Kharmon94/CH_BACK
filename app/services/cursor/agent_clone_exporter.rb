module Cursor
  class AgentCloneExporter
    def initialize(linked_database, composer_id, on_progress: nil)
      @linked_database = linked_database
      @composer_id = composer_id
      @on_progress = on_progress
      @group = ComposerGroup.new(linked_database, composer_id)
    end

    def call
      @on_progress&.call(10, "fetching_bubbles")
      composers = @group.sessions
      bubbles = @group.all_bubbles
      @on_progress&.call(60, "rendering")

      session_name = composers.values.first&.dig("name") || "Cursor Agent Session"
      sanitized = session_name.gsub(/[^\w\s-]/, "").strip.gsub(/\s+/, "_")
      filename = "Agent_Clone_#{sanitized}.md"

      content = AgentClone::Template.new(
        group: @group,
        composers: composers,
        bubbles: bubbles,
        filename: filename
      ).render

      @on_progress&.call(90, "saving")
      { content: content, filename: filename, session_count: composers.size }
    end
  end
end
