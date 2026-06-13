# frozen_string_literal: true

module Api
  module V1
    class UploadsController < ProtectedController
      DEFAULT_MAX_FILE_SIZE = 15.megabytes

      def create
        file = params[:file]

        unless file.respond_to?(:read)
          render json: { error: "file is required" }, status: :unprocessable_entity
          return
        end

        authorize! :create, :image_upload

        if file.size.to_i > DEFAULT_MAX_FILE_SIZE
          render json: { error: "File is too large (max #{DEFAULT_MAX_FILE_SIZE / 1.megabyte}MB)" }, status: :unprocessable_entity
          return
        end

        content_type = file.content_type.presence || Marcel::MimeType.for(file.original_filename) || "application/octet-stream"
        unless content_type.start_with?("image/")
          render json: { error: "Only image uploads are supported" }, status: :unprocessable_entity
          return
        end

        blob = ActiveStorage::Blob.create_and_upload!(
          io: file,
          filename: file.original_filename,
          content_type: content_type
        )

        render json: { signed_id: blob.signed_id }
      rescue ActiveStorage::IntegrityError
        render json: { error: "Upload failed integrity check" }, status: :unprocessable_entity
      end
    end
  end
end
