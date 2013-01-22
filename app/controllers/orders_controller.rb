class OrdersController < ApplicationController
                     
  $sort_fields = %w( `orders`.`created_at` `orders`.`deliver_by_date` `stores.name` )
  
  def index
    redirect_to :action => "search"
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
        send_data render_to_string(:action => 'show_order', :handlers => [:axlsx], :locals => {:order => @order}), :filename => @order.filename, :type => "application/vnd.openxmlformates-officedocument.spreadsheetml.sheet"
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
      redirect_to orders_path
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
  
  def search 
    sort_condition = params[:sort] || 0
    sort_direction = params[:dir] || "desc"
    # Pagination is not a major concerns as 
    # subsequent pages pulled using AJAX in most
    # cases.
    page = (params[:page] || 1 ).to_i
    per_page = (params[:per_page] || $per_page).to_i
    
    search_results = Order.search_orders( params, per_page, page)     
    
    respond_to do |format|
      format.html do
        
        @page_title = "Orders Dashboard"
        @search_title = "Orders "
        
        # Sanitize Params
        [:page, :action, :controller, :format, :es].each{ |key| params.delete(key) }
        @search_params = params
        
        @orders = search_results[:results]
        @facets = search_results[:facets]
        @more_pages = search_results[:more_pages]
        @current_page = page
        
        # The following code block is used to properly
        # list the Find Order options and to mark of the one that is selected
        today = Date.today.to_date
        search_date_params = { :start_date => (params[:start_date] || today ).to_date, :end_date => (params[:end_date] || today ).to_date }

        @pre_defined_search_options = []
        @pre_defined_search_options.push(["Created today", \
                                        {:start_date => today, :end_date => today}]  )                             
        @pre_defined_search_options.push(["Created this week", \
                                        {:start_date => today.days_to_week_start.days.ago.to_date, :end_date => today }]) unless today.monday?
                                        
        @pre_defined_search_options.push(["From last week", {:end_date => ((today.days_to_week_start).days.ago - 1.day).to_date, :start_date => ((today.days_to_week_start).days.ago.to_date - 1.week).to_date}])
        
        @pre_defined_search_options.push(["Created this month", \
                                          {:start_date => (today.day - 1).days.ago.to_date, :end_date => today}])
                                          
                                          
        @pre_defined_search_options.each do |search_specs|
          if search_specs[1] == search_date_params
            search_specs[1][:class] = 'current' 
            @search_title += search_specs[0].titlecase
            break
          end
        end
        
        # Further defining the title for the search page
        @search_title += ' for ' + Company.find(params[:company_id])[:name] if params[:company_id].present? 
        @search_title += ' in ' + State.find(['US', params[:shipping_state]])[:state_name] if params[:shipping_state].present?
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
