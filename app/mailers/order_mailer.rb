class OrderMailer < ActionMailer::Base
  default from: "from@example.com"

  def email_order( mailto, order, attachment_body )
    @order = order
    attachments["OrderSheetForInvoice_#{order[:invoice_number]}.xls"] = { 
	:content_type => "application/xls",
	:body => attachment_body
    }
    mail( :to => mailto,
    :subject => "Order Sheet for Invoice Number: #{order[:invoice_number]}"
    )
  end
end
