class ProductsController < ApplicationController
  def index
    @page_title = "Products"
    @product_categories = ProductCategory.all.order(:name)

    if request.params && request.params[:product_category].present?
      @products = Product.where(["product_category_id = ?", request.params[:product_category].to_i]).order(:sort_order_for_order_sheet)
    end
  end
  

  def products_by_category
    products = Product.where(["product_category_id = ?", params[:product_category_id].to_i]).order(:sort_order_for_order_sheet)

    if products.size > 0 
      render(partial: "list", collection: products)
    else 
      '<tr><td colspan="5" class="text-center"><em>No products found</em></td></tr>'.html_safe
    end
  end

  def show
    product = Product.includes(:product_category).find(params[:id])
    session[:last_page] = request.env['HTTP_REFERER'] || nil \
        unless \
          request.env['HTTP_REFERER'] == new_product_url \
          || request.env['HTTP_REFERER'] == edit_product_url(product)

    @page_title = "Product: #{product[:name]}"
    render locals: {product: product}
  end
  
  def new
    session[:last_page] = request.env['HTTP_REFERER']

    product = Product.new
    @page_title = "New Product"

    render locals: {product: product}
  end
  
  
  def create
    # if params[:category_type] == "new"
    #   product_category = ProductCategory.find_or_create_by_name( {:name => params[:new_category], :limited_availability => !( params[:product][:available_from].blank? && params[:product][:available_till].blank? )})
    #   params[:product][:product_category_id] = product_category[:id]
    # end
    
    product = Product.new(params[:product])
    if product.save
      redirect_to product_path( product )
    else
      @page_title = "New Product"
      render "new", locals: {product: product}
    end    
  end
  
  def edit
    product = Product.find( params[:id] )
    @page_title = "Edit Product: #{product[:name]}"

    render locals: {product: product}
  end
  
  def update
    
    product = Product.find( params[:id] )
    if product.update(product_params)
      redirect_to product_path(product)
    else
      render "edit", locals: {product: product}
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
    # params[:product][:active] = (params[:product][:active] == "true" || params[:product][:active].to_s == "1")
    params
      .require(:product)
      .permit(
        :name, 
        :code, 
        :product_category_id, 
        :from, 
        :till, 
        :sort_order_for_order_sheet, 
        :active)
  end
end
