require "rails_helper"

RSpec.describe Cursor::DatabaseLocator do
  describe ".locate" do
    it "requires a filename" do
      expect {
        described_class.locate(filename: "", byte_size: 1)
      }.to raise_error(ArgumentError, /Filename/)
    end

    it "requires a positive byte size" do
      expect {
        described_class.locate(filename: "state.vscdb", byte_size: 0)
      }.to raise_error(ArgumentError, /size/)
    end

    it "finds a unique file under configured search roots" do
      Dir.mktmpdir do |dir|
        path = File.join(dir, "state.vscdb")
        File.write(path, "x" * 128)

        original = ENV["CURSOR_DB_SEARCH_ROOTS"]
        ENV["CURSOR_DB_SEARCH_ROOTS"] = dir
        result = described_class.locate(filename: "state.vscdb", byte_size: 128)
        expect(result).to eq(path)
      ensure
        ENV["CURSOR_DB_SEARCH_ROOTS"] = original
      end
    end

    it "raises when no file matches" do
      original = ENV["CURSOR_DB_SEARCH_ROOTS"]
      ENV["CURSOR_DB_SEARCH_ROOTS"] = "/tmp"
      expect {
        described_class.locate(filename: "missing.vscdb", byte_size: 999_999)
      }.to raise_error(ArgumentError, /Could not find/)
    ensure
      ENV["CURSOR_DB_SEARCH_ROOTS"] = original
    end
  end
end
