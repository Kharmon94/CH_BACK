module Api
  module V1
    class HealthController < PublicController
      def show
        render json: { status: "ok" }
      end
    end
  end
end
