# frozen_string_literal: true

require "rails_helper"

RSpec.describe Cursor::Connection do
  describe ".open" do
    it "opens a Cursor database regardless of .vscdb extension" do
      Dir.mktmpdir do |dir|
        path = File.join(dir, "state.vscdb")
        db = SQLite3::Database.new(path)
        db.execute("CREATE TABLE cursorDiskKV (key TEXT PRIMARY KEY, value TEXT NOT NULL)")
        db.execute("INSERT INTO cursorDiskKV (key, value) VALUES (?, ?)", [ "composerData:test", "{}" ])
        db.close

        conn = described_class.open(path)
        tables = conn.execute("SELECT name FROM sqlite_master WHERE type='table' AND name='cursorDiskKV'")
        expect(tables).not_to be_empty
        conn.close
      end
    end

    it "reads live state.vscdb when available" do
      path = Pathname("/mnt/c/Users/kharm/AppData/Roaming/Cursor/User/globalStorage/state.vscdb").expand_path.to_s
      skip "No live state.vscdb available" unless File.file?(path)

      expect(described_class).to receive(:open_uri).with(/immutable=1/).and_call_original
      conn = described_class.open(path)
      count = conn.get_first_value("SELECT COUNT(*) FROM cursorDiskKV WHERE key LIKE 'composerData:%'")
      expect(count).to be > 0
      conn.close
    end
  end
end
