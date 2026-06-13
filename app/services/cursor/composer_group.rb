module Cursor
  class ComposerGroup
    BUBBLE_BATCH_SIZE = 100

    def initialize(linked_database, composer_id)
      @linked_database = linked_database
      @composer_id = composer_id
    end

    def primary_composer_id
      sessions.max_by { |_, payload| primary_session_score(payload) }&.first
    end

    def sessions
      @sessions ||= load_sessions
    end

    def session_count
      sessions.size
    end

    def composer_payload(composer_id)
      load_composer_data(composer_id)
    end

    def all_bubbles
      bubbles = {}
      sessions.each do |composer_id, payload|
        bubbles.merge!(BubbleFetcher.new(@linked_database.path, composer_id, payload).call)
      end
      bubbles
    end

    private

    def load_sessions
      primary = load_composer_data(@composer_id)
      name = primary["name"]
      return { @composer_id => primary } if name.blank?

      conn = Connection.open(@linked_database.path)
      rows = conn.execute(
        "SELECT replace(key, 'composerData:', '') AS composer_id, value FROM cursorDiskKV " \
        "WHERE key LIKE 'composerData:%' AND json_extract(value, '$.name') = ?",
        [ name ]
      )
      rows.each_with_object({}) do |(cid, value), hash|
        hash[cid] = JSON.parse(value)
      end
    ensure
      conn&.close
    end

    def load_composer_data(composer_id)
      conn = Connection.open(@linked_database.path)
      row = conn.get_first_value(
        "SELECT value FROM cursorDiskKV WHERE key = ?",
        [ "composerData:#{composer_id}" ]
      )
      raise ArgumentError, "Composer not found: #{composer_id}" unless row

      JSON.parse(row)
    ensure
      conn&.close
    end

    def primary_session_score(payload)
      mode = (payload["unifiedMode"] || payload["forceMode"] || "").to_s.downcase
      is_agent = mode == "agent" ? 1 : 0
      [ is_agent, payload["lastUpdatedAt"].to_i ]
    end
  end
end
