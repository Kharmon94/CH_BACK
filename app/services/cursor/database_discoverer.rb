# frozen_string_literal: true

module Cursor
  class DatabaseDiscoverer
    CURSOR_DATABASE_FILENAME = "state.vscdb"

    def self.discover
      new.discover
    end

    def discover
      paths = candidate_paths.uniq.select { |path| File.file?(path) }

      case paths.size
      when 0
        { found: false, path: nil, count: 0 }
      when 1
        { found: true, path: paths.first, count: 1 }
      else
        { found: true, path: nil, count: paths.size, candidates: paths.first(5) }
      end
    end

    private

    def candidate_paths
      extra_roots = ENV.fetch("CURSOR_DB_SEARCH_ROOTS", "").split(",").map(&:strip).reject(&:blank?)
      if extra_roots.any?
        paths = []
        extra_roots.each do |root|
          paths.concat(Dir.glob(File.join(root, "**", CURSOR_DATABASE_FILENAME)))
        end
        return paths
      end

      paths = []
      paths.concat(windows_paths)
      paths.concat(macos_paths)
      paths.concat(linux_paths)
      paths.concat(wsl_paths)
      paths
    end

    def windows_paths
      appdata = ENV["APPDATA"].presence
      return [] unless appdata

      [ File.join(appdata, "Cursor", "User", "globalStorage", CURSOR_DATABASE_FILENAME) ]
    end

    def macos_paths
      home = ENV["HOME"].presence
      return [] unless home

      [ File.join(home, "Library", "Application Support", "Cursor", "User", "globalStorage", CURSOR_DATABASE_FILENAME) ]
    end

    def linux_paths
      home = ENV["HOME"].presence
      return [] unless home

      [
        File.join(home, ".config", "Cursor", "User", "globalStorage", CURSOR_DATABASE_FILENAME),
        File.join(home, ".cursor", CURSOR_DATABASE_FILENAME)
      ]
    end

    def wsl_paths
      paths = []
      paths.concat(Dir.glob("/mnt/c/Users/*/AppData/Roaming/Cursor/User/globalStorage/#{CURSOR_DATABASE_FILENAME}"))
      paths.concat(Dir.glob("/mnt/c/Users/*/AppData/Roaming/Cursor/User/workspaceStorage/**/#{CURSOR_DATABASE_FILENAME}"))
      paths
    end
  end
end
