# frozen_string_literal: true

class JwtService
  class << self
    def encode(payload, exp = 24.hours.from_now)
      payload[:exp] = exp.to_i
      JWT.encode(payload, secret_key, "HS256")
    end

    def decode(token)
      body = JWT.decode(token, secret_key, true, { algorithm: "HS256" })[0]
      HashWithIndifferentAccess.new(body)
    rescue JWT::DecodeError
      nil
    end

    private

    def secret_key
      ENV.fetch("JWT_SECRET_KEY") { Rails.application.credentials.secret_key_base }
    end
  end
end
