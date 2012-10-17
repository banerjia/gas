class OrdersController < ApplicationController
  def index
    
  end
  
  def show
    
  end
  
  def new
    @store = Store.find(params[:store_id])
    @page_title = "New Order for #{@store[:name]}"
  end
  
  def create
    @store = Store.find(params[:store_id])
    @order = @store.orders.new(params[:order]).product_orders.new( params[:order][:product_order])
    if @order.save
      redirect_to :action => "show", :controller => "stores", :id => params[:store_id]
    else
      render "new"
    end
  end
  
  def edit
    
  end
  
  def update
    
  end
  
  def destroy
    
  end
end
