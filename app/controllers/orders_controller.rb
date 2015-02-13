class OrdersController < ApplicationController
                     
  $sort_fields = %w( `orders`.`created_at` `orders`.`deliver_by_date` `stores.name` )
  
  def index
    redirect_to :action => "search"
  end
  
  def show
    # This approach has been taken to reduce the number of SELECT statements
    order = Order.includes([:store, {:product_orders => [:product]}]).find( params[:id])

    session[:last_page] = request.env['HTTP_REFERER'] || nil \
        unless \
          request.env['HTTP_REFERER'] == new_order_url \
          || request.env['HTTP_REFERER'] == store_new_order_url(order.store) \
          || request.env['HTTP_REFERER'] == edit_order_url(order)
    
    
    @page_title = "Order Sheet: #{order[:id]}"
    @browser_title = "Order: #{order[:id]}"
    respond_to do |format|
      format.html { render :locals => {:order => order} }
      format.xlsx do 
        send_data render_to_string(:action => 'show_order', :handlers => [:axlsx], :locals => {:order => order}), :filename => order.filename, :type => "application/vnd.openxmlformates-officedocument.spreadsheetml.sheet"
      end
    end
  end
  
  def new

    session[:last_page] = request.env['HTTP_REFERER'] || nil

    # Initializing the object within the scope of the action
    order = nil 

    @page_title = "New Order"

    # Doesn't matter if the store_id is present in the params hash
    # this statement will still work
    order = Order.new({store_id: params[:store_id]})
    # order[:created_at] = Date.today.strftime("%m/%d/%Y")

    # Creating at least one product_order associated with the order
    order.product_orders.build

    @page_title = @page_title + " for #{order.store.full_name}" if params[:store_id].present?
    @browser_title = "New Order"
    render locals: {order: order}
  end
  
  def create
    sanitized_params = agg_n_remove_dups(order_params)

    order = Order.new(sanitized_params)

    if order.save      
      redirect_to orders_path
    else
      render "new", locals: {order: order}
    end
  end
  
  def edit
    order = Order.includes([:store, {:product_orders => [:product]}]).find(params[:id])
    @page_title = "Edit Order: #{order[:id]}"

    render locals: {order: order}
  end
  
  def update
    order = Order.find( params[:id] )

    sanitized_params = agg_n_remove_dups( order_params )

    if order.update( sanitized_params )
      redirect_to orders_path
    else
      render "edit", locals: {order: order}
    end
  end
  
  def destroy
    orders_to_delete = []
    if params[:id].present?
      orders_to_delete.push( params[:id])
    else
      orders_to_delete = params[:orders].map{ |id| id.to_i }  
    end    
    Order.where({ id: orders_to_delete }).destroy_all
    render status: 200, json: {sucess: true, redirect_url: session[:last_page] || orders_search_path}.to_json
  end
  
  def send_email
    send_to = params[:email] || ENV['order_email']
    optional_message = params[:email_body] unless !params[:email_body].present?

    order_id = params[:order].map{ |id| id.to_i }

    order = Order.includes([{product_orders: [:product, :volume_unit]}, :store]).find( order_id )
    
    email = OrderMailer.email_order( send_to, order, optional_message )
    email.deliver
    # render :nothing => true
    render status: 200, json: {sucess: true}.to_json
  end
  
  def search 
    params = (request.params || {}).clone
    params = params.reject{|k,v| v.blank? || v.empty?} #unless params.nil?
    # sort_condition = params[:sort] || 0
    # sort_direction = params[:dir] || "desc"

    # Sanitizing the params for return value
    [:action, :controller, :format, :es].each{ |key| params.delete(key) }

    # Pagination is not a major concerns as 
    # subsequent pages pulled using AJAX in most
    # cases.
    params[:page] = (params[:page] || 1 ).to_i
    params[:per_page] = (params[:per_page] || 10).to_i    
    
    # Initialize both dates to nil so that in case the "else"
    # part is executed the missing date is always set to nil
    # start_date = end_date = nil
    # if !(params[:start_date].present? || params[:end_date].present?)
    #     # If neither dates are specified then default to today
    #     start_date = end_date = Date.today
    # else
    #   # Otherwise assign the values if they are present. 
    #   start_date = params[:start_date] if params[:start_date].present?
    #   end_date = params[:end_date] if params[:end_date].present?
    # end 

    params[:start_date] = Date.strptime(params[:start_date], '%m/%d/%Y') if params[:start_date].present? && /^\d{4}\-\d{2}\-\d{2}/.match(params[:start_date]).nil?
    params[:end_date] = Date.strptime(params[:end_date], '%m/%d/%Y') if params[:end_date].present? && /^\d{4}\-\d{2}\-\d{2}/.match(params[:end_date]).nil?

    search_results = Order.search( params )   
     
    # Make view responsible for tracking pages
    page = params[:page]

    return_value = { \
      orders: search_results[:results], \
      total_results: search_results[:total], \
      aggs: search_results[:aggs], \
      more_pages: (search_results[:total].to_f/params[:per_page].to_f > page), \
      options: params
    }
    respond_to do |format|
      format.html do
        
        @page_title = "Orders"
        
        render locals: return_value
      end
      
      format.json do
        [:aggs].each { |key| return_value.delete(key)}
        render :json => return_value.to_json
      end
    end
  end

private
	def order_params
		params.require(:order).permit(
      :store_id, 
      :invoice_number, 
      :route_id, 
      :delivery_dow, 
      :created_at, 
      :email_sent, 
      product_orders_attributes: [
        :product_id,
        :quantity
      ])
	end

  def agg_n_remove_dups( order_attr)
    return order_attr if order_attr[:product_orders_attributes].nil?
    return_value = order_attr.dup
    keys_to_delete = []
    unique_pos = {}
    return_value[:product_orders_attributes].each do |po_attr|
      # po_attr = [<index_value>, {product_id => xxx, quantity => xxx}]
      po_key = po_attr.first
      po = po_attr.last
      key = "po_#{po[:product_id]}"
      if unique_pos.has_key?(key)
        keys_to_delete.push( po_key )
        original_po_key = unique_pos[key]
        return_value[:product_orders_attributes][original_po_key][:quantity] = return_value[:product_orders_attributes][original_po_key][:quantity].to_i + po[:quantity].to_i
      else
        unique_pos = unique_pos.merge({key => po_key})
      end
    end

    keys_to_delete.each { |key| return_value[:product_orders_attributes].delete(key)}

    return return_value
  end
end
