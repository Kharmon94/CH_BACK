class ApplicationMailer < ActionMailer::Base
  default from: -> { MailerFrom.formatted }
  layout "mailer"
end
