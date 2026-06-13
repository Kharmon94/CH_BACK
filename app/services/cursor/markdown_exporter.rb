module Cursor
  class MarkdownExporter
    def initialize(linked_database, composer_id, on_progress: nil)
      @linked_database = linked_database
      @composer_id = composer_id
      @on_progress = on_progress
      @group = ComposerGroup.new(linked_database, composer_id)
    end

    def call
      sessions = @group.sessions.sort_by { |_, p| p["createdAt"].to_i }
      total = sessions.size
      lines = [ "# Cursor Chat History Export\n" ]

      sessions.each_with_index do |(composer_id, payload), index|
        bubbles = BubbleFetcher.new(@linked_database.path, composer_id, payload).call
        lines << render_session(index + 1, composer_id, payload, bubbles)
        @on_progress&.call(((index + 1).to_f / total * 100).round) if total.positive?
      end

      lines.join("\n")
    end

    private

    def render_session(index, composer_id, payload, bubbles)
      name = payload["name"] || composer_id
      status = payload["status"] || "unknown"
      mode = payload["unifiedMode"] || payload["forceMode"] || "unknown"
      created = format_timestamp(payload["createdAt"])
      updated = format_timestamp(payload["lastUpdatedAt"])

      out = []
      out << "## Session #{index}: #{name}"
      out << ""
      out << "- Status: #{status}"
      out << "- Mode: #{mode}"
      out << "- Created: #{created}" if created.present?
      out << "- Updated: #{updated}" if updated.present?
      out << ""

      headers = payload["fullConversationHeadersOnly"] || []
      headers.each do |header|
        next unless header.is_a?(Hash)

        bubble_id = header["bubbleId"]
        bubble_type = header["type"]
        next unless bubble_id

        bubble = bubbles[[ composer_id, bubble_id ]]
        next unless bubble

        message = MessageTextExtractor.extract(bubble, include_tools: true)
        next if message.blank?

        role = MessageTextExtractor.role_label(bubble_type)
        out << "### #{role}"
        out << ""
        out << message
        out << ""
        out << "---"
        out << ""
      end

      out.join("\n")
    end

    def format_timestamp(ms)
      return "" unless ms.is_a?(Numeric) && ms.positive?

      Time.at(ms / 1000.0).utc.strftime("%Y-%m-%d %H:%M UTC")
    rescue StandardError
      ""
    end
  end
end
