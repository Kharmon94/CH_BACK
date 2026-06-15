# frozen_string_literal: true

module Api
  module V1
    module Local
      class DiscoverController < ProtectedController
        def show
          render json: Cursor::DatabaseDiscoverer.discover
        end
      end
    end
  end
end
