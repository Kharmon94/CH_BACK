# frozen_string_literal: true

class UserMailer < ApplicationMailer
  def reset_password_instructions(record, token, opts = {})
    @user = record
    @reset_url = "#{FrontendOrigin.primary.chomp('/')}/app/reset-password?reset_token=#{token}"

    mail(
      to: record.email,
      subject: "Reset your Cursor Help password",
      template_name: "reset_password"
    )
  end
end
