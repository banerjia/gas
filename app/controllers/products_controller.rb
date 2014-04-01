class ProductsController < ApplicationController
  def index
    @page_title = "Products"
    @products_listing_by_category = ProductCategory.find(:all, :include => [:products])
  end
  
  def show
    
  end
  
  def new
    @product = Product.new
    @page_title = "New Product"
  end
  
  
  def create
    if params[:category_type] == "new"
      product_category = ProductCategory.find_or_create_by_name( {:name => params[:new_category], :limited_availability => !( params[:product][:available_from].blank? && params[:product][:available_till].blank? )})
      params[:product][:product_category_id] = product_category[:id]
    end
    
    @product = Product.new(params[:product])
    if @product.save
      redirect_to :action => (params[:commit] == "Save" ? "index" : "new")
    else
      render "new"
    end    
  end
  
  def edit
    @product = Product.find( params[:id] )
    @page_title = "Update Product: #{@product[:name]}"
  end
  
  def update
    if params[:category_type] == "new"
      product_category = ProductCategory.new( {:name => params[:new_category], :limited_availabilty => !( params[:product][:available_from].blank? && params[:product][:available_till].blank? )})
      params[:product][:product_category_id] = product_category[:id]
    end
    
    @product = Product.find( params[:id] )
    if @product.update_attributes!(product_params)
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
  
private
  def product_params
    params.require(:product).permit(:name, :code, :product_category_id, :available_from, :available_till, :sort_order_for_order_sheet, :active)
  end
end
