# frozen_string_literal: true

require "net/http"
require "uri"

module Auth
  class GoogleOauth
    AUTHORIZE_URL = "https://accounts.google.com/o/oauth2/v2/auth"
    TOKEN_URL = "https://oauth2.googleapis.com/token"
    USERINFO_URL = "https://oauth2.googleapis.com/oauth2/v3/userinfo"
    PROVIDER = "google"

    class AdminAccountError < StandardError; end

    class << self
      def client_id
        ENV.fetch("GOOGLE_CLIENT_ID").to_s.strip
      end

      def client_secret
        ENV.fetch("GOOGLE_CLIENT_SECRET").to_s.strip
      end

      def redirect_uri
        explicit = ENV["GOOGLE_OAUTH_REDIRECT_URI"].to_s.strip.chomp("/")
        return explicit if explicit.present?

        api_origin = ENV["API_PUBLIC_ORIGIN"].to_s.strip.chomp("/")
        return "#{api_origin}/api/v1/auth/google/callback" if api_origin.present?

        raise KeyError, "GOOGLE_OAUTH_REDIRECT_URI"
      end

      def authorize_url(state:)
        query = URI.encode_www_form(
          client_id: client_id,
          redirect_uri: redirect_uri,
          response_type: "code",
          scope: "openid email profile",
          state: state,
          access_type: "online",
          prompt: "select_account"
        )
        "#{AUTHORIZE_URL}?#{query}"
      end

      def store_state!(state, payload)
        Rails.cache.write("google_oauth_state:#{state}", payload, expires_in: 15.minutes)
      end

      def consume_state!(state)
        key = "google_oauth_state:#{state}"
        payload = Rails.cache.read(key)
        Rails.cache.delete(key)
        payload
      end

      def exchange_code!(code:)
        uri = URI(TOKEN_URL)
        http = Net::HTTP.new(uri.host, uri.port)
        http.use_ssl = true
        req = Net::HTTP::Post.new(uri)
        req["Content-Type"] = "application/x-www-form-urlencoded"
        req.body = URI.encode_www_form(
          code: code,
          client_id: client_id,
          client_secret: client_secret,
          redirect_uri: redirect_uri,
          grant_type: "authorization_code"
        )
        res = http.request(req)
        parsed = res.body.to_s.strip.present? ? JSON.parse(res.body) : {}
        unless res.is_a?(Net::HTTPSuccess)
          msg = parsed["error_description"] || parsed["error"] || res.message
          raise StandardError, msg.to_s
        end
        parsed
      end

      def fetch_userinfo(access_token:)
        uri = URI(USERINFO_URL)
        http = Net::HTTP.new(uri.host, uri.port)
        http.use_ssl = true
        req = Net::HTTP::Get.new(uri)
        req["Authorization"] = "Bearer #{access_token}"
        res = http.request(req)
        parsed = res.body.to_s.strip.present? ? JSON.parse(res.body) : {}
        unless res.is_a?(Net::HTTPSuccess)
          raise StandardError, parsed["error_description"] || parsed["error"] || res.message
        end
        parsed
      end

      def user_from_google!(profile)
        email = profile["email"].to_s.strip.downcase
        uid = profile["sub"].to_s
        raise StandardError, "Google account missing email" if email.blank?

        existing = User.find_by(provider: PROVIDER, uid: uid) || User.find_by(email: email)
        if existing
          raise AdminAccountError, "Use admin login for this email." if existing.admin?
          existing.update!(provider: PROVIDER, uid: uid) if existing.provider.blank?
          return existing
        end

        password = SecureRandom.hex(24)
        user = User.create!(
          email: email,
          name: profile["name"],
          password: password,
          password_confirmation: password,
          role: :user,
          provider: PROVIDER,
          uid: uid
        )
        TeamProvisioner.call(user, name: profile["given_name"] || profile["name"])
        user
      end

      def frontend_callback_url(token:, next_path: "/app")
        base = FrontendOrigin.primary.chomp("/")
        path = next_path.to_s.start_with?("/") ? next_path : "/app"
        "#{base}/app/oauth/google/callback?token=#{CGI.escape(token)}&next=#{CGI.escape(path)}"
      end

      def frontend_error_url(message:, next_path: "/app/login")
        base = FrontendOrigin.primary.chomp("/")
        path = next_path.to_s.start_with?("/") ? next_path : "/app/login"
        "#{base}#{path}?oauth_error=#{CGI.escape(message)}"
      end
    end
  end
end
