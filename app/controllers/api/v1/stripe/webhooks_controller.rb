module Api
  module V1
    module Stripe
      class WebhooksController < ApplicationController
        def create
          payload = request.body.read
          sig_header = request.env["HTTP_STRIPE_SIGNATURE"]

          event = StripeService.verify_webhook(payload, sig_header)
          StripeService.handle_webhook(event)
          head :ok
        rescue ::Stripe::SignatureVerificationError
          render json: { error: "Invalid signature" }, status: :bad_request
        rescue KeyError, ::Stripe::StripeError => e
          render json: { error: e.message }, status: :bad_request
        end
      end
    end
  end
end
