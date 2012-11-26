class OrdersController < ApplicationController
  def index
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
    @store = Store.find( params[:store_id] )
    @order = Order.find( params[:id], :include => {:product_orders => [:product]})
    @products_by_category = Hash.new
    product_orders = @order.product_orders
    product_category_ids = product_orders.map{ |product_order| product_order.product[:product_category_id]}.uniq
    @product_categories = ProductCategory.find( product_category_ids )
    @product_categories.each do | category |
      @products_by_category["category_#{category[:id]}"] = \
          product_orders.map{ |product_order| product_order if product_order.product[:product_category_id] ==  category[:id] }.compact
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
