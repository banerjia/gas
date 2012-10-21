class OrdersController < ApplicationController
  def index
    @store = Store.find(params[:store_id])
    @store_orders = @store.orders
    @page_title = "Orders for #{@store[:name]}"
    
    respond_to do |format|
      format.html
      format.json do
        render :json => @store_orders.to_json
      end
    end
  end
  
  def show
    
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
    @store = Store.find(params[:store_id])
    @order = Order.find(params[:id])
    @page_title = "Update Order: #{@order[:invoice_number]}"
  end
  
  def update
    @order = Order.find( params[:id] )
    store = Store.find( params[:store_id] )
    if @order.update_attributes!( params[:order] )
      redirect_to store_orders_path(store)
    else
      @store = store
      render "edit"
    end
  end
  
  def destroy
    
  end
end
