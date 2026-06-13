# frozen_string_literal: true

# FRONTEND_ORIGIN may be comma-separated for CORS (preview + production). Mailers and
# OAuth redirects need a single canonical URL — use the first entry.
module FrontendOrigin
  module_function

  def origins_from_env
    return [] if ENV["FRONTEND_ORIGIN"].blank?

    ENV["FRONTEND_ORIGIN"].split(",").map { |o| o.strip.chomp("/") }.compact_blank
  end

  def primary
    origins_from_env.first || "http://localhost:5173"
  end
end
