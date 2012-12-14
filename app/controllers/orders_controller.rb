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
    company_id = params[:company_id]
    state_code = params[:shipping_state]
    page = (params[:page] || 1 ).to_i
    per_page = (params[:per_page] || $per_page).to_i
    q = params[:q] if params[:q].present?
    facet = params[:facet].split(':') if params[:facet].present?
    #params[:page].delete if params[:page].present?
    
     
    tire_order_listing = Order.tire.search :per_page => per_page, :page => page do 
      query do
           boolean do
             must { string q } if defined?(q) && q
             must { range :created_at, {:gt => 1.day.ago, :lt => Date.today + 1.day } }
           end
      end

      filter :term, :company_id => company_id if company_id
      filter :term, :ship_to_state_code => state_code if state_code

      facet 'states' do
        terms :ship_to_state_code, :order => 'term'
      end  
      
      facet 'chains' do 
        terms :company_id, :order => 'term'
      end  
      
      facet 'delivery_day' do
        terms :deliver_by_day, :order => 'term'
      end
        
      sort  {by :created_at, 'desc'}
    end

    more_pages = (tire_order_listing.total_pages > page )
    
    facets = Hash.new

    # Populating States Facet
    if tire_order_listing.facets['states']['terms'].count > 1
      facets['states'] = []
      tire_order_listing.facets['states']['terms'].each_with_index do |state,index| 
        state[:state_name] = State.find(:first, :conditions => {:state_code => state['term']} )[:state_name]
        facets['states'].push(state)
      end
    end
    
    # Populating Chains Facet
    if tire_order_listing.facets['chains']['terms'].count > 1
      facets['chains'] = []
      tire_order_listing.facets['chains']['terms'].each_with_index do |chain,index|
        chain[:company_name] = Company.find(chain['term'].to_i)[:name]
        facets['chains'].push(chain)
      end
    end
    
    # Populating Delivery Day Facets
    facets['delivery_day'] = tire_order_listing.facets['delivery_day']['terms'] if tire_order_listing.facets['delivery_day']['terms'].count > 1
    
    # If an extra record was returned for the "more records" test then get rid of it from the final listing
    # per_page - 1 => because array indexes start from 0
    order_listing = tire_order_listing[0..per_page - 1]
    
    respond_to do |format|
      format.html do
        @page_title = "Orders Dashboard"
        search_title = "Recent Orders"
        # Sanitize Params
        [:page, :action, :controller, :format].each{ |key| params.delete(key) }
        search_params = params
        render "orders/dashboard", :locals => { :orders => order_listing, :facets => facets, :more_pages => more_pages, :current_page => page, :search_params => search_params, :search_title => search_title }
      end
      format.json do
        return_value = Hash.new
        return_value[:orders] = order_listing
        return_value[:facets] = facets
        return_value[:debug] = search_params
        return_value[:more_pages] = more_pages
        render :json => return_value.to_json
      end
    end
  end
end
