class NewsletterMailer < ActionMailer::Base
  default from: "webdesign.banerji@gmail.com"

  # Subject can be set in your I18n file at config/locales/en.yml
  # with the following lookup:
  #
  #   en.newsletter_mailer.weekly.subject
  #
  def weekly
    @greeting = "Hi"

    mail to: "bill.graeters@gmail.com", subject: "Graeters Order for Invoice# 12345"
  end
end

