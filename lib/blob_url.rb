# frozen_string_literal: true

class BlobUrl
  def self.for(attachment, fallback = nil)
    return fallback if attachment.blank?

    target =
      if attachment.is_a?(ActiveStorage::Attachment) || attachment.is_a?(ActiveStorage::Blob)
        attachment
      elsif attachment.respond_to?(:attached?)
        return fallback unless attachment.attached?

        attachment
      else
        return fallback
      end

    Rails.application.routes.url_helpers.rails_blob_url(
      target,
      **Rails.application.routes.default_url_options
    )
  rescue StandardError
    fallback
  end
end
