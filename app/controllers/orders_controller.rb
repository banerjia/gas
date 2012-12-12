class OrdersController < ApplicationController
                     
  $sort_fields = %w( `orders`.`created_at` `orders`.`deliver_by_date` `stores.name` )
  
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
    sort_condition = params[:sort] || 0
    sort_direction = params[:dir] || "desc"
    # Look for explanation at REF:1
    params[:created_at_begin]= params[:created_at_begin] || 2.weeks.ago
    page = (params[:page] || 1 ).to_i
    per_page = (params[:per_page] || $per_page).to_i
    orders_conditions = []
    
    # REF:1
    # We are absolutely certain that the begin date will be provided
    # because the default listing is for orders from the last 2 weeks. 
    orders_conditions.push( "`orders`.`created_at` >= '#{params[:created_at_begin]}'" )
  
    # Adding other conditions as provided
    orders_conditions.push( "`orders`.`store_id` = #{params[:store_id]}" ) if params[:store_id].present?
    orders_conditions.push( "`orders`.`created_at` <= '#{params[:created_at_end]}'" ) if params[:created_at_end].present?
    orders_conditions.push( "`orders`.`invoice_number` = '#{params[:po]}'" ) if params[:po].present?
    
    condition_string = orders_conditions.join( " and " )
    
    #Intentionally adding one more to the per_page to do a "more records" test
    order_listing = Order.find( :all, \
                                :conditions => condition_string, \
                                :order => $sort_fields[sort_condition] + ' ' + sort_direction,
                                :joins => [:store => [:company]],
                                :limit => per_page + 1,
                                :offset => ((page - 1) * per_page),
                                :select => '`orders`.`id`, 
                                            `orders`.`invoice_number`,
                                            `orders`.`deliver_by_day`,
                                            `orders`.`created_at`,
                                            `orders`.`store_id`, 
                                            `stores`.`name` as `store_name`,
                                            `companies`.`name` as `company_name`,
                                            `companies`.`id` as `company_id`'
    )
    
    more_pages = (order_listing.size > per_page )
    
    # If an extra record was returned for the "more records" test then get rid of it from the final listing
    # per_page - 1 => because array indexes start from 0
    order_listing = order_listing[0..per_page - 1]
    
    respond_to do |format|
      format.html do
        @page_title = "Orders Dashboard"
        render "orders/dashboard", :locals => { :orders => order_listing, :more_pages => more_pages, :current_page => page, :search_params => params }
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
