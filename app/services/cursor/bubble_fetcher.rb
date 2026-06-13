module Cursor
  class BubbleFetcher
    BATCH_SIZE = 100

    def initialize(db_path, composer_id, payload)
      @db_path = db_path
      @composer_id = composer_id
      @payload = payload
    end

    def call
      headers = @payload["fullConversationHeadersOnly"] || []
      bubble_ids = headers.filter_map { |h| h["bubbleId"] if h.is_a?(Hash) }
      return {} if bubble_ids.empty?

      bubbles = {}
      conn = Connection.open(@db_path)

      bubble_ids.each_slice(BATCH_SIZE) do |batch|
        keys = batch.map { |bid| "bubbleId:#{@composer_id}:#{bid}" }
        placeholders = ([ "?" ] * keys.length).join(",")
        rows = conn.execute(
          "SELECT key, value FROM cursorDiskKV WHERE key IN (#{placeholders})",
          keys
        )
        rows.each do |key, value|
          parts = key.split(":", 3)
          next unless parts.length == 3

          bubbles[[ parts[1], parts[2] ]] = JSON.parse(value)
        end
      end

      bubbles
    ensure
      conn&.close
    end
  end
end
