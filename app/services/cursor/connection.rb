module Cursor
  class Connection
    def self.open(path)
      resolved = File.expand_path(path)
      raise ArgumentError, "Database not found: #{resolved}" unless File.file?(resolved)

      encoded = URI::DEFAULT_PARSER.escape(resolved)
      uri = "file:#{encoded}?mode=ro"
      SQLite3::Database.new(uri, uri: true)
    end
  end
end
