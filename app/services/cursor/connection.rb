# frozen_string_literal: true

module Cursor
  class Connection
    VSCDB_EXTENSION = ".vscdb"

    def self.open(path)
      resolved = File.expand_path(path)
      raise ArgumentError, "Database not found: #{resolved}" unless File.file?(resolved)

      encoded = URI::DEFAULT_PARSER.escape(resolved)
      params = vscdb?(resolved) ? "mode=ro&immutable=1" : "mode=ro"
      open_uri("file:#{encoded}?#{params}")
    end

    def self.vscdb?(path)
      File.extname(path).casecmp(VSCDB_EXTENSION).zero?
    end

    def self.open_uri(uri)
      SQLite3::Database.new(uri, uri: true)
    end

    private_class_method :open_uri, :vscdb?
  end
end
