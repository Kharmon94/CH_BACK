module Cursor
  class ComposerIndexer
    INDEX_SQL = <<~SQL.squish
      SELECT
        replace(key, 'composerData:', '') AS composer_id,
        json_extract(value, '$.name') AS name,
        json_extract(value, '$.status') AS status,
        COALESCE(json_extract(value, '$.unifiedMode'), json_extract(value, '$.forceMode')) AS mode,
        json_extract(value, '$.createdAt') AS created_at,
        json_extract(value, '$.lastUpdatedAt') AS updated_at,
        json_array_length(json_extract(value, '$.fullConversationHeadersOnly')) AS message_count
      FROM cursorDiskKV
      WHERE key LIKE 'composerData:%'
      ORDER BY updated_at DESC
    SQL

    def initialize(linked_database, on_progress: nil)
      @linked_database = linked_database
      @on_progress = on_progress
    end

    def call
      conn = Connection.open(@linked_database.path)
      rows = conn.execute(INDEX_SQL)
      total = rows.length
      indexed = 0

      ComposerCache.transaction do
        ComposerCache.where(linked_database_id: @linked_database.id).delete_all

        rows.each do |row|
          composer_id, name, status, mode, created_at, updated_at, message_count = row
          ComposerCache.create!(
            linked_database_id: @linked_database.id,
            composer_id: composer_id,
            name: name,
            status: status,
            mode: mode,
            message_count: message_count.to_i,
            created_at_ms: created_at&.to_i,
            updated_at_ms: updated_at&.to_i
          )
          indexed += 1
          @on_progress&.call((indexed.to_f / total * 100).round) if total.positive?
        end
      end

      @linked_database.update!(
        composer_count: indexed,
        last_indexed_at: Time.current,
        index_status: "completed",
        index_error: nil
      )
      indexed
    ensure
      conn&.close
    end
  end
end
