# frozen_string_literal: true

module Api
  module V1
    module Auth
      class GoogleController < PublicController
        GENERIC_OAUTH_ERROR = "Google sign-in failed. Please try again."

        def start
          unless google_configured?
            render json: { error: "Google sign-in is not configured" }, status: :service_unavailable
            return
          end

          state = SecureRandom.hex(24)
          next_path = params[:next].to_s
          next_path = "/app" unless next_path.start_with?("/")

          ::Auth::GoogleOauth.store_state!(state, { "next" => next_path })

          render json: {
            authorize_url: ::Auth::GoogleOauth.authorize_url(state: state),
            redirect_uri: ::Auth::GoogleOauth.redirect_uri
          }
        end

        def callback
          state = params[:state].to_s
          payload = ::Auth::GoogleOauth.consume_state!(state)
          next_path = payload.is_a?(Hash) ? (payload["next"].presence || "/app") : "/app/login"

          if payload.blank?
            redirect_to ::Auth::GoogleOauth.frontend_error_url(message: "Invalid or expired sign-in state.", next_path: next_path),
              allow_other_host: true
            return
          end

          if params[:error].present?
            message = params[:error].to_s == "access_denied" ? "Google sign-in was cancelled." : GENERIC_OAUTH_ERROR
            redirect_to ::Auth::GoogleOauth.frontend_error_url(message: message, next_path: next_path),
              allow_other_host: true
            return
          end

          code = params[:code].to_s
          if code.blank?
            redirect_to ::Auth::GoogleOauth.frontend_error_url(message: "Missing authorization code.", next_path: next_path),
              allow_other_host: true
            return
          end

          token_response = ::Auth::GoogleOauth.exchange_code!(code: code)
          profile = ::Auth::GoogleOauth.fetch_userinfo(access_token: token_response["access_token"])
          user = ::Auth::GoogleOauth.user_from_google!(profile)
          jwt = JwtService.encode(user.jwt_payload)
          redirect_to ::Auth::GoogleOauth.frontend_callback_url(token: jwt, next_path: next_path),
            allow_other_host: true
        rescue ::Auth::GoogleOauth::AdminAccountError => e
          redirect_to ::Auth::GoogleOauth.frontend_error_url(message: e.message, next_path: "/app/login"),
            allow_other_host: true
        rescue StandardError => e
          Rails.logger.warn("[GoogleOAuth] #{e.class}: #{e.message}")
          redirect_to ::Auth::GoogleOauth.frontend_error_url(message: GENERIC_OAUTH_ERROR, next_path: next_path),
            allow_other_host: true
        end

        private

        def google_configured?
          ENV["GOOGLE_CLIENT_ID"].present? &&
            ENV["GOOGLE_CLIENT_SECRET"].present? &&
            (ENV["GOOGLE_OAUTH_REDIRECT_URI"].present? || ENV["API_PUBLIC_ORIGIN"].present?)
        end
      end
    end
  end
end
