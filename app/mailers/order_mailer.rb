class OrderMailer < ActionMailer::Base
  default from: "Graeters Orders <tagoretownapps+graeters_orders@gmail.com>"
  def email_order( mailto, order, attachment_body )
    @order = order
    attachments["OrderSheetForInvoice_#{order[:invoice_number]}.xls"] = { 
	      :content_type => "application/octet-stream",
	      :body => attachment_body
      }
    mail( :to => mailto,
    :subject => "Order Sheet for Invoice Number: #{order[:invoice_number]}"
    )
  end
end
