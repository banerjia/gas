class OrderMailer < ActionMailer::Base
  default from: "from@example.com"

  def email_order( mailto, order )
	encoded_content = store_order_path( order[:store_id], order[:id], :format => :xls )
	attachments[ "Order#{order[:invoice_number]}" ] = {
		:mime_type => 'application/xls',
		:content => encoded_content
	}
	mail( :to => mailto,
	     :subject => "New Order > Invoice Number: #{order[:invoice_number]}"
	    )
  end
end
