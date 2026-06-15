require "rails_helper"

RSpec.describe Cursor::DatabaseDiscoverer do
  before do
    allow_any_instance_of(described_class).to receive(:windows_paths).and_return([])
    allow_any_instance_of(described_class).to receive(:macos_paths).and_return([])
    allow_any_instance_of(described_class).to receive(:linux_paths).and_return([])
    allow_any_instance_of(described_class).to receive(:wsl_paths).and_return([])
  end

  describe ".discover" do
    it "returns not found when no database exists" do
      original = ENV["CURSOR_DB_SEARCH_ROOTS"]
      ENV["CURSOR_DB_SEARCH_ROOTS"] = "/tmp/cursorhelp-missing-#{SecureRandom.hex(4)}"
      result = described_class.discover
      expect(result[:found]).to be(false)
      expect(result[:path]).to be_nil
    ensure
      ENV["CURSOR_DB_SEARCH_ROOTS"] = original
    end

    it "returns a unique match under configured search roots" do
      Dir.mktmpdir do |dir|
        path = File.join(dir, "state.vscdb")
        File.write(path, "x" * 64)

        original = ENV["CURSOR_DB_SEARCH_ROOTS"]
        ENV["CURSOR_DB_SEARCH_ROOTS"] = dir
        result = described_class.discover
        expect(result[:found]).to be(true)
        expect(result[:path]).to eq(path)
        expect(result[:count]).to eq(1)
      ensure
        ENV["CURSOR_DB_SEARCH_ROOTS"] = original
      end
    end

    it "returns multiple candidates when more than one file matches" do
      Dir.mktmpdir do |dir|
        FileUtils.mkdir_p(File.join(dir, "a"))
        FileUtils.mkdir_p(File.join(dir, "b"))
        File.write(File.join(dir, "a", "state.vscdb"), "x" * 64)
        File.write(File.join(dir, "b", "state.vscdb"), "x" * 64)

        original = ENV["CURSOR_DB_SEARCH_ROOTS"]
        ENV["CURSOR_DB_SEARCH_ROOTS"] = dir
        result = described_class.discover
        expect(result[:found]).to be(true)
        expect(result[:path]).to be_nil
        expect(result[:count]).to eq(2)
        expect(result[:candidates].size).to eq(2)
      ensure
        ENV["CURSOR_DB_SEARCH_ROOTS"] = original
      end
    end
  end
end
