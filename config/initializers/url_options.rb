# frozen_string_literal: true

Rails.application.routes.default_url_options = {
  host: ENV.fetch("API_PUBLIC_ORIGIN", "http://localhost:3000").sub(%r{\Ahttps?://}, "").split("/").first,
  protocol: ENV.fetch("API_PUBLIC_ORIGIN", "http://localhost:3000").start_with?("https") ? "https" : "http"
}
