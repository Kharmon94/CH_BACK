# frozen_string_literal: true

class UserMailer < ApplicationMailer
  def reset_password(user, token)
    @user = user
    @reset_url = "#{FrontendOrigin.primary.chomp('/')}/app/login?reset_token=#{token}"

    mail(
      to: user.email,
      subject: "Reset your Cursor Help password"
    )
  end
end
