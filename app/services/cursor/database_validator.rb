module Cursor
  class DatabaseValidator
    def self.validate!(path)
      conn = Connection.open(path)
      tables = conn.execute("SELECT name FROM sqlite_master WHERE type='table' AND name='cursorDiskKV'")
      raise ArgumentError, "Not a Cursor state database (missing cursorDiskKV table)" if tables.empty?

      true
    ensure
      conn&.close
    end
  end
end
