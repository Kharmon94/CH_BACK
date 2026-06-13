# frozen_string_literal: true

class TeamInviteMailer < ApplicationMailer
  def invite(team_invite)
    @invite = team_invite
    @team = team_invite.team
    @accept_url = "#{FrontendOrigin.primary.chomp('/')}/app/invite/#{team_invite.token}"

    mail(
      to: team_invite.email,
      subject: "You're invited to #{@team.name} on Cursor Help"
    )
  end
end
