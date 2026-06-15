# frozen_string_literal: true

module Cloud
  class LicenseClient
    CACHE_TTL = 5.minutes

    LicenseData = Struct.new(:tier, :pro, :export_count, :exports_remaining, keyword_init: true)

    def self.fetch(team_id:, token:)
      new(team_id:, token:).fetch
    end

    def self.reserve_export!(team_id:, token:, format:)
      new(team_id:, token:).reserve_export!(format:)
    end

    def initialize(team_id:, token:)
      @team_id = team_id
      @token = token
    end

    def fetch
      cache_key = "cloud_license/#{team_id}"
      Rails.cache.fetch(cache_key, expires_in: CACHE_TTL) do
        fetch_from_cloud
      end
    end

    def reserve_export!(format:)
      uri = URI.join(cloud_api_base, "/exports/reserve")
      request = Net::HTTP::Post.new(uri)
      request["Authorization"] = "Bearer #{token}"
      request["X-Team-Id"] = team_id.to_s
      request["Accept"] = "application/json"
      request["Content-Type"] = "application/json"
      request.body = { format: format }.to_json

      response = Net::HTTP.start(uri.host, uri.port, use_ssl: uri.scheme == "https") do |http|
        http.request(request)
      end

      unless response.is_a?(Net::HTTPSuccess)
        body = JSON.parse(response.body) rescue {}
        raise ArgumentError, body["error"] || "Could not reserve export quota (#{response.code})"
      end

      body = JSON.parse(response.body)
      LicenseData.new(
        tier: body.dig("license", "tier") || body["tier"] || "free",
        pro: body.dig("license", "pro") == true || body["pro"] == true,
        export_count: body.dig("license", "export_count").to_i,
        exports_remaining: body.dig("license", "exports_remaining")
      )
    rescue JSON::ParserError, SocketError, Errno::ECONNREFUSED, Net::OpenTimeout => e
      Rails.logger.warn("[Cloud::LicenseClient] reserve failed: #{e.class}: #{e.message}")
      raise ArgumentError, "Could not reach cloud to verify export quota. Check your connection and sign-in."
    end

    private

    attr_reader :team_id, :token

    def fetch_from_cloud
      uri = URI.join(cloud_api_base, "/license")
      request = Net::HTTP::Get.new(uri)
      request["Authorization"] = "Bearer #{token}"
      request["X-Team-Id"] = team_id.to_s
      request["Accept"] = "application/json"

      response = Net::HTTP.start(uri.host, uri.port, use_ssl: uri.scheme == "https") do |http|
        http.request(request)
      end

      unless response.is_a?(Net::HTTPSuccess)
        raise ArgumentError, "Could not verify license with cloud (#{response.code})"
      end

      body = JSON.parse(response.body)
      LicenseData.new(
        tier: body["tier"] || "free",
        pro: body["pro"] == true,
        export_count: body["export_count"].to_i,
        exports_remaining: body["exports_remaining"]
      )
    rescue JSON::ParserError, SocketError, Errno::ECONNREFUSED, Net::OpenTimeout => e
      Rails.logger.warn("[Cloud::LicenseClient] #{e.class}: #{e.message}")
      fallback_local_license
    end

    def fallback_local_license
      team = Team.includes(:license).find_by(id: team_id)
      LicenseData.new(
        tier: team&.license&.tier || "free",
        pro: team&.pro? || false,
        export_count: team&.export_count.to_i,
        exports_remaining: team&.pro? ? nil : [ 1 - team.export_count.to_i, 0 ].max
      )
    end

    def cloud_api_base
      base = ENV.fetch("CLOUD_API_URL", "https://api.cursorhelp.com").chomp("/")
      base.end_with?("/api/v1") ? "#{base}/" : "#{base}/api/v1/"
    end
  end
end
