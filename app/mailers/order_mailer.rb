class OrderMailer < ActionMailer::Base
  default from: "Graeters Orders <market.banerji@gmail.com>"

  def email_order( mailto, order_list, add_message)
    view_context = ActionView::Base.new(ActionController::Base.view_paths, {})
    order_list.each do |order|
      attachments[order.filename] = { 
        mime_type: Mime::XLSX,
	      :body => view_context.render( :template => 'orders/show_order', :formats => [:xlsx], :handlers => [:axlsx], :locals => {:order => order} )
      }  

      order.update_columns({email_sent: true, email_sent_date: Date.today})
      order.__elasticsearch__.update_document
    end

    if order_list.size > 1
      # Handle emails with multiple orders
      pos = order_list.map{ |order| order[:invoice_number] }.join(", ")
      mail( :to => mailto, :subject => "Graeter's Cloud: Orders" ) do |format|
        format.html { render "email_multiple_orders", :locals => { :orders => order_list, :optional_message => add_message } }
      end
    else
      # Handle instance when only one order is being emailed
      # format defaults to email_order.html.erb because of naming conventions
      order = order_list.first
      mail( :to => mailto, :subject => "Graeter's Cloud: Order #{order[:id]}" ) do |format|
        format.html { render :locals => {:order => order, :optional_message => add_message } }
      end
    end
  end
end
