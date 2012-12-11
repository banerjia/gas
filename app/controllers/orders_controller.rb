class OrdersController < ApplicationController
  $order_dashboard_sort = [ \
                      '`orders`.`created_at`', \
                      '`orders`.`delivery_date`' \
                     ]
  
  $order_dashboard_conditions = [
                      ['`orders`.`created_at` >= ?', 2.weeks.ago], \
                      '`orders`.`fulfilled` = 0' \
                    ]
  
  def index
    redirect_to :action => "dashboard" unless params[:store_id].present?
    
    limit = params[:l]
    offset = params[:o]
    @store = Store.find(params[:store_id])
    @store_orders = @store.orders.order("created_at desc").limit(limit).offset(offset)
    @page_title = "Orders for #{@store[:name]}"
    
    respond_to do |format|
      format.html
      format.json do
        return_value = Hash.new
        return_value[:orders] = @store_orders
        render :json => return_value.to_json
      end
    end
  end
  
  def show
    # This apprach has been taken to reduce the number of SELECT statements
    @order = Order.find( params[:id], :include => {:product_orders => [:product]})
    @store = Store.find( @order[:store_id] )
    
    
    @page_title = "Order Sheet for Invoice " + @order[:invoice_number]
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
      redirect_to store_orders_path(@store)
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
    type_of_listing = params[:type] || 0
    sort_condition = params[:sort] || 0
    sort_direction = params[:dir] || "desc"
    page = (params[:page] || 1 ).to_i - 1
    per_page = (params[:per_page] || $per_page).to_i
    
    #Intentionally adding one more to the per_page to do a "more records" test
    order_listing = Order.find( :all, \
                                :conditions => $order_dashboard_conditions[type_of_listing], \
                                :order => $order_dashboard_sort[sort_condition] + ' ' + sort_direction,
                                :joins => :store,
                                :limit => per_page + 1,
                                :offset => (page * per_page),
                                :select => '`orders`.`id`, `orders`.`invoice_number`,`orders`.`invoice_amount`,`orders`.`store_id`, `orders`.`deliver_by_day`,`orders`.`created_at`, `orders`.`fulfilled`, `stores`.`name` as `store_name`')
    
    more_pages = (order_listing.size > per_page )
    
    # If an extra record was returned for the "more records" test then get rid of it from the final listing
    order_listing = order_listing[0..$per_page - 1]
    
    respond_to do |format|
      format.html do
        @page_title = "Orders Dashboard"
        render "orders/dashboard", :locals => { :orders => order_listing, :more_pages => more_pages }
      end
      format.json do
        return_value = Hash.new
        return_value[:orders] = order_listing
        return_value[:more_pages] = more_pages
        render :json => return_value.to_json
      end
    end
  end
end
