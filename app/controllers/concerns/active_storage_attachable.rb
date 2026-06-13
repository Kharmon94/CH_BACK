# frozen_string_literal: true

module ActiveStorageAttachable
  extend ActiveSupport::Concern

  private

  def attach_blob!(attachment, signed_id)
    return if signed_id.blank?

    blob = ActiveStorage::Blob.find_signed!(signed_id)
    attachment.attach(blob)
  rescue ActiveRecord::RecordNotFound, ActiveSupport::MessageVerifier::InvalidSignature
    raise ActiveRecord::RecordInvalid.new(attachment.record), "Invalid or expired upload"
  end
end
