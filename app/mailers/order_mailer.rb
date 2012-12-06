class OrderMailer < ActionMailer::Base
  default from: "Graeters Orders <tagoretownapps+graeters_orders@gmail.com>"
  def email_order( mailto, order, order_docs )
    @order = order.first
    view_context = ActionView::Base.new(ActionController::Base.view_paths, {})
    order_docs.each do |order_doc|
      attachments["OrderSheetForInvoice_#{order_doc[:invoice_number]}.xls"] = { 
	      :content_type => "application/octet-stream",
	      :body => view_context.render( :template => 'orders/show.xls.erb', :locals => {:order => Order.find(order_doc[:order_id])} )
      }
    end
#    if order.size < 2
#      mail( :to => mailto,
#            :subject => "Order Sheet for Invoice Number: #{@order[:invoice_number]}"
#          )
#    else
      mail( :to => mailto,
            :subject => "Orders"
          ) do |format|
            format.html { render "email_multiple_orders", :locals => {:orders => order } }
          end
 #   end
 #   render :nothing => true

  end
end
