class OrderMailer < ActionMailer::Base
  default from: "Graeters Orders <tagoretownapps+graeters_orders@gmail.com>"

  def email_order( mailto, order_list, add_message)
    view_context = ActionView::Base.new(ActionController::Base.view_paths, {})
    order_list.each do |order|
      attachments["OrderDetailsForPO-#{order[:invoice_number]}.xlsx"] = { 
	      :content_type => "application/octet-stream",
	      :body => view_context.render( :template => 'orders/show', :handlers => [:axlsx], :locals => {:order => order} )
      }
    end

    if order_list.size > 1
      # Handle emails with multiple orders
      pos = order_list.map{ |order| order[:invoice_number] }.join(", ")
      mail( :to => mailto, :subject => "Order Details for POs: #{pos}" ) do |format|
        format.html { render "email_multiple_orders", :locals => { :orders => order_list, :optional_message => add_message } }
      end
    else
      # Handle instance when only one order is being emailed
      # format defaults to email_order.html.erb because of naming conventions
      order = order_list.first
      mail( :to => mailto, :subject => "Order Details for PO: #{order[:invoice_number]}" ) do |format|
        format.html { render :locals => {:order => order, :optional_message => add_message } }
      end
    end
  end
end