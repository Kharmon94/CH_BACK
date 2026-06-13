# frozen_string_literal: true

module FrontendOrigin
  module_function

  def primary
    raw = ENV.fetch("FRONTEND_ORIGIN", ENV.fetch("FRONTEND_URL", "http://localhost:5173"))
    raw.to_s.split(",").map(&:strip).reject(&:blank?).first || "http://localhost:5173"
  end
end
