# frozen_string_literal: true

require "rails_helper"

RSpec.describe Cursor::DatabaseValidator do
  describe ".validate!" do
    it "accepts state.vscdb with cursorDiskKV" do
      Dir.mktmpdir do |dir|
        path = File.join(dir, "state.vscdb")
        db = SQLite3::Database.new(path)
        db.execute("CREATE TABLE cursorDiskKV (key TEXT PRIMARY KEY, value TEXT NOT NULL)")
        db.close

        expect(described_class.validate!(path)).to be true
      end
    end
  end
end
