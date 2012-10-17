class ProductsController < ApplicationController
  def index
    @page_title = "Products"
    @product_list = Product.find(:all, :order => "created_at desc")
  end
  
  def show
    
  end
  
  def new
    @product = Product.new
    @page_title = "New Product"
  end
  
  
  def create
    @product = Product.new(params[:product])
    if @product.save
      redirect_to :action => "index"
    else
      render "new"
    end    
  end
  
  def edit
    @product = Product.find( params[:id] )
    @page_title = "Update Product: #{@product[:name]}"
  end
  
  def update
    @product = Product.find( params[:id] )
    if @product.update_attributes!(params[:product])
      redirect_to :action => "index"
    else
      render "edit"
    end
  end
  
  def destroy
    # Using an update_all to toggle the delete functionality 
    # reduces the SELECT queries made in order to delete
    # the record. 
    Product.update_all( "active = !active", {:id => params[:id]})
    redirect_to :action => "index"
  end
end
