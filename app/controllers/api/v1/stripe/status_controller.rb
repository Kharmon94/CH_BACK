# frozen_string_literal: true

module Api
  module V1
    module Stripe
      class StatusController < ApplicationController
        def show
          render json: StripeConfig.status_payload
        end
      end
    end
  end
end
