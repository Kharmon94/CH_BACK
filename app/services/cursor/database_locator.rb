# frozen_string_literal: true

module Cursor
  class DatabaseLocator
    CURSOR_GLOBAL_STORAGE = "AppData/Roaming/Cursor/User/globalStorage".freeze

    def self.locate(filename:, byte_size:, last_modified_ms: nil)
      new.locate(filename: filename, byte_size: byte_size, last_modified_ms: last_modified_ms)
    end

    def locate(filename:, byte_size:, last_modified_ms: nil)
      name = filename.to_s.strip
      raise ArgumentError, "Filename is required" if name.blank?
      raise ArgumentError, "File size is required" if byte_size.to_i <= 0

      matches = candidate_paths(name).select { |path| file_matches?(path, byte_size, last_modified_ms) }

      case matches.size
      when 1
        matches.first
      when 0
        raise ArgumentError,
          "Could not find that file on the server. Paste the full path below (WSL: /mnt/c/Users/…)."
      else
        raise ArgumentError, "Multiple files match. Paste the full path to the correct database."
      end
    end

    private

    def candidate_paths(filename)
      paths = []

      extra_roots = ENV.fetch("CURSOR_DB_SEARCH_ROOTS", "").split(",").map(&:strip).reject(&:blank?)
      extra_roots.each do |root|
        paths.concat(Dir.glob(File.join(root, "**", filename)))
      end

      home = ENV["HOME"].presence
      if home
        paths << File.join(home, ".cursor", filename)
        paths << File.join(home, ".config", "Cursor", "User", "globalStorage", filename)
      end

      paths.concat(Dir.glob("/mnt/c/Users/*/AppData/Roaming/Cursor/User/globalStorage/#{filename}"))
      paths.concat(Dir.glob("/mnt/c/Users/*/AppData/Roaming/Cursor/User/workspaceStorage/**/#{filename}"))

      paths.uniq.select { |path| File.file?(path) }
    end

    def file_matches?(path, byte_size, last_modified_ms)
      return false unless File.size(path) == byte_size.to_i

      if last_modified_ms.present?
        file_ms = (File.mtime(path).to_f * 1000).round
        request_ms = last_modified_ms.to_i
        (file_ms - request_ms).abs <= 2000
      else
        true
      end
    end
  end
end
