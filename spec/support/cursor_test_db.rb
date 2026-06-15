# frozen_string_literal: true

module CursorTestDb
  FILENAME = "state.vscdb"

  # Prefer stable local copies for integration specs; live state.vscdb is tested separately.
  CANDIDATES = [
    Rails.root.join("../../ChatHistory/#{FILENAME}"),
    Rails.root.join("../../ChatHistory/state.db"),
    Pathname("/mnt/c/Users/kharm/AppData/Roaming/Cursor/User/globalStorage/state.vscdb.backup"),
    Pathname("/mnt/c/Users/kharm/AppData/Roaming/Cursor/User/globalStorage/#{FILENAME}")
  ].freeze

  def self.path
    env = ENV["CURSOR_TEST_DB"].presence
    return env if env && File.file?(env)

    CANDIDATES.map { |candidate| candidate.expand_path.to_s }.find { |candidate| File.file?(candidate) }
  end
end
