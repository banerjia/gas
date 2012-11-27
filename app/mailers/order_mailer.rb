class OrderMailer < ActionMailer::Base
  default from: "from@example.com"

  def email_order( mailto, order )
    @order = order
    mail( :to => mailto,
    :subject => "Order Sheet for Invoice Number: #{order[:invoice_number]}"
    )
  end
end
