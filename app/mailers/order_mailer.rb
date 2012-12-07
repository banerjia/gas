class OrderMailer < ActionMailer::Base
  default from: "Graeters Orders <tagoretownapps+graeters_orders@gmail.com>"

  def email_order( mailto, order_list, dummy )
    view_context = ActionView::Base.new(ActionController::Base.view_paths, {})
    order_list.each do |order|
      attachments["OrderSheetForInvoice_#{order[:invoice_number]}.xlsx"] = { 
	      :content_type => "application/octet-stream",
	      :body => view_context.render( :template => 'orders/show.xlsx.axlsx', :locals => {:order => order} )
      }
    end

    if order_list.size > 1
      # Handle emails with multiple orders
      
      mail( :to => mailto, :subject => "Graeters Cloud: Order sheets") do |format|
        format.html do 
          render "email_multiple_orders", :locals => { :orders => order_list }
        end
      end
    else
      # Handle instance when only one order is being emailed
      # format defaults to email_order.html.erb because of naming conventions

      order = order_list
      mail( :to => mailto, 
            :subject =>  "Order Sheet for PO: #{order[:invoice_number]}"
          )
    end
  end
end
