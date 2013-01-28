class OrderMailer < ActionMailer::Base
  default from: "Graeters Orders <tagoretownapps@gmail.com>"

  def email_order( mailto, order_list, add_message)
    view_context = ActionView::Base.new(ActionController::Base.view_paths, {})
    order_list.each do |order|
      attachments[order.filename] = { 
	      :content_type => "application/octet-stream",
	      :body => view_context.render( :template => 'orders/show_order', :handlers => [:axlsx], :locals => {:order => order} )
      }  
      order[:email_sent] = true
      order[:email_sent_date] = Date.today
      order.save
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
