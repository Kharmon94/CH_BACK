# frozen_string_literal: true

module DesktopMode
  module_function

  def enabled?
    Rails.env.desktop?
  end

  def data_dir
    @data_dir ||= Pathname.new(Cursorhelp::Paths.user_data_dir)
  end

  def ensure_data_dir!
    Cursorhelp::Paths.ensure_user_data_dir!
  end
end
