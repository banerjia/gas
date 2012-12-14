class OrdersController < ApplicationController
                     
  $sort_fields = %w( `orders`.`created_at` `orders`.`deliver_by_date` `stores.name` )
  
  def index
  end
  
  def show
    # This apprach has been taken to reduce the number of SELECT statements
    @order = Order.find( params[:id], :include => {:product_orders => [:product]})
    @store = Store.find( @order[:store_id] )
    
    
    @page_title = "Order Sheet for PO: " + @order[:invoice_number]
    @browser_title = "Invoice: " + @order[:invoice_number]
    
    respond_to do |format|
      format.html { render :locals => {:order => @order} }
      format.xlsx do 
        send_data render_to_string(:action => 'show_order', :handlers => [:axlsx], :locals => {:order => @order}), :filename => "OrderforPO_" + @order[:invoice_number]+".xlsx", :type => "application/vnd.openxmlformates-officedocument.spreadsheetml.sheet"
      end
    end
  end
  
  def new
    @store = Store.find(params[:store_id])
    @order = @store.orders.build 
    @order.product_orders.build
    @page_title = "New Order for #{@store[:name]}"
  end
  
  def create
    @store = Store.find(params[:store_id])
    @order = @store.orders.new(params[:order])
    if @order.save
      redirect_to orders_path
    else
      render "new"
    end
  end
  
  def edit
    @order = Order.find(params[:id])
    @store = Store.find(@order[:store_id])
    @page_title = "Update Order: #{@order[:invoice_number]}"
  end
  
  def update
    @order = Order.find( params[:id] )
    store = Store.find( @order[:store_id] )
    if @order.update_attributes!( params[:order] )
      redirect_to store_orders_path(store)
    else
      @store = store
      render "edit"
    end
  end
  
  def destroy
    orders_to_delete = params[:id].split(/\D+/).map{ |id| id.to_i }
    orders_to_delete.each do | order_id |
      Order.find( order_id ).destroy
    end
    redirect_to :action => "dashboard"
  end
  
  def send_email
    send_to = params[:email]
    optional_message = params[:email_body]
    order_id = params[:id].split(/\D+/).map{ |id| id.to_i }

    order = Order.find( order_id, :include => [{:product_orders => [:product, :volume_unit]}, :store])
    
    email = OrderMailer.email_order( send_to, order, optional_message )
    email.deliver
    render :nothing => true
  end
  
  def dashboard 
    sort_condition = params[:sort] || 0
    sort_direction = params[:dir] || "desc"
    # Look for explanation at REF:1
    page = (params[:page] || 1 ).to_i
    per_page = (params[:per_page] || $per_page).to_i
    
    search_results = Order.order_search( params, per_page, page)     
    
    respond_to do |format|
      format.html do
        @page_title = "Orders Dashboard"
        search_title = "Recent Orders"
        # Sanitize Params
        [:page, :action, :controller, :format].each{ |key| params.delete(key) }
        search_params = params
        render "orders/dashboard", :locals => { :orders => search_results[:results] , :facets => search_results[:facets], :more_pages => search_results[:more_pages], :current_page => page, :search_params => search_params, :search_title => search_title }
      end
      format.json do
        return_value = Hash.new
        return_value[:orders] = search_results[:results]
        return_value[:facets] = search_results[:facets]
        return_value[:more_pages] = search_results[:more_pages]
        render :json => return_value.to_json
      end
    end
  end
end
