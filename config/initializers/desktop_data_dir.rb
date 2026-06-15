# frozen_string_literal: true

if Rails.env.desktop?
  data_dir = Pathname.new(ENV.fetch("CURSORHELP_DATA_DIR", File.expand_path("~/.cursorhelp")))
  data_dir.mkpath
end
