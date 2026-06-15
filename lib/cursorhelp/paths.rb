# frozen_string_literal: true

require "fileutils"

module Cursorhelp
  module Paths
    module_function

    def user_data_dir
      ENV["CURSORHELP_USER_DATA"].presence ||
        ENV["CURSORHELP_DATA_DIR"].presence ||
        File.join(Dir.home, ".cursorhelp")
    end

    def ensure_user_data_dir!
      FileUtils.mkdir_p(user_data_dir)
      user_data_dir
    end

    def primary_db_path
      File.join(ensure_user_data_dir!, "desktop.sqlite3")
    end

    def queue_db_path
      File.join(ensure_user_data_dir!, "desktop_queue.sqlite3")
    end

    def exports_dir
      path = File.join(ensure_user_data_dir!, "exports")
      FileUtils.mkdir_p(path)
      path
    end
  end
end
