# frozen_string_literal: true

require "mail"

module MailerFrom
  module_function

  DEFAULT_ADDRESS = "noreply@cursorhelp.com"

  def formatted
    raw = ENV.fetch("MAILER_FROM", DEFAULT_ADDRESS).to_s.strip
    raw = raw.delete_prefix('"').delete_suffix('"')
    raw = raw.delete_prefix("'").delete_suffix("'")
    return raw if raw.include?("<")

    email = raw
    name = ENV["MAILER_FROM_NAME"].presence || "Cursor Help"
    Mail::Address.new.tap do |a|
      a.address = email
      a.display_name = name
    end.to_s
  end
end
