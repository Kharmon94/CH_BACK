# frozen_string_literal: true

Devise.setup do |config|
  config.mailer = "UserMailer"
  config.parent_mailer = "ApplicationMailer"
  require "devise/orm/active_record"
  config.case_insensitive_keys = [ :email ]
  config.strip_whitespace_keys = [ :email ]
  config.skip_session_storage = [ :http_auth ]
  config.stretches = Rails.env.test? ? 1 : 12
  config.reconfirmable = false
  config.password_length = 8..128
  config.email_regexp = /\A[^@\s]+@[^@\s]+\z/
  config.reset_password_within = 6.hours
  config.sign_out_via = :delete
end
