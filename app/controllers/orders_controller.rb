class OrdersController < ApplicationController
                     
  $sort_fields = %w( `orders`.`created_at` `orders`.`deliver_by_date` `stores.name` )
  
  def index
    redirect_to :action => "search"
  end
  
  def show
    # This approach has been taken to reduce the number of SELECT statements
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
    params[:order][:store_id] = params[:store_id]
    @order = Order.new(order_params)
    if @order.save
      Order.tire.index.refresh
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
    if @order.update_attributes!( order_params )
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
    Order.tire.index.refresh
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
    # sort_condition = params[:sort] || 0
    # sort_direction = params[:dir] || "desc"

    # Sanitizing the params for return value
    [:action, :controller, :format, :es].each{ |key| params.delete(key) }

    # Pagination is not a major concerns as 
    # subsequent pages pulled using AJAX in most
    # cases.
    params[:page] = (params[:page] || 1 ).to_i
    params[:per_page] = (params[:per_page] || $per_page).to_i    
    
    # Initialize both dates to nil so that in case the "else"
    # part is executed the missing date is always set to nil
    start_date = end_date = nil
    if !(params[:start_date].present? || params[:end_date].present?)
        # If neither dates are specified then default to today
        start_date = end_date = Date.today.to_date
    else
      # Otherwise assign the values if they are present. 
      start_date = params[:start_date] if params[:start_date].present?
      end_date = params[:end_date] if params[:end_date].present?
    end 

    params[:start_date] = start_date
    params[:end_date] = end_date

    search_results = Order.search( params )   
    
    # The following code block is used to properly
    # list the Find Order options and to mark of the one that is selected
    today = Date.today.to_date
    search_date_params = { :start_date => (params[:start_date] || today ).to_date, :end_date => (params[:end_date] || today ).to_date }

    predefined_search_options = []
    predefined_search_options.push(["Created today", \
                                    {:start_date => today, :end_date => today}]  )                             
    predefined_search_options.push(["Created this week", \
                                    {:start_date => today.days_to_week_start.days.ago.to_date, :end_date => today }]) unless today.monday?
                                    
    predefined_search_options.push(["From last week", {:end_date => ((today.days_to_week_start).days.ago - 1.day).to_date, :start_date => ((today.days_to_week_start).days.ago.to_date - 1.week).to_date}])
    
    predefined_search_options.push(["Created this month", \
                                      {:start_date => (today.day - 1).days.ago.to_date, :end_date => today}])
     
    # Make view responsible for tracking pages
    page = params.delete(:page)  

    return_value = { \
      orders: search_results[:results], \
      total_results: search_results[:total], \
      aggs: search_results[:aggs], \
      more_pages: (search_results[:total].to_f/params[:per_page].to_f > page), \
      options: params, \
      predefined_search_criteria: predefined_search_options

    }
    respond_to do |format|
      format.html do
        
        @page_title = "Orders"
        
        render locals: return_value
      end
      
      format.json do
        #[:aggs, :predefined_search_criteria].each { |key| return_value.delete(key)}
        render :json => return_value.to_json
      end
    end
  end

private
	def order_params
		params.require(:order).permit(:store_id, :invoice_number, :route_id, :delivery_dow, :created_at, :email_sent, :product_orders_attributes => [:product_id,:quantity])
	end
end
