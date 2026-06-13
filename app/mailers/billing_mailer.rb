# frozen_string_literal: true

class BillingMailer < ApplicationMailer
  def subscription_confirmed(team, user)
    @team = team
    @user = user
    @billing_url = "#{FrontendOrigin.primary.chomp('/')}/app/teams/#{team.id}/billing"

    mail(
      to: user.email,
      subject: "Cursor Help Pro activated for #{team.name}"
    )
  end
end
