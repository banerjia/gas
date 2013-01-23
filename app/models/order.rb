class Order < ActiveRecord::Base
  include Tire::Model::Search
  include Tire::Model::Callbacks
  
  # Associations
  has_many :product_orders, :dependent => :destroy
  has_many :products, :through => :product_orders
  has_many :product_categories, :through => :products, :group => :product_category_id
  belongs_to :route
  
  belongs_to :store, :counter_cache => true
  
  # Attributes
  attr_accessible :invoice_number, :route_id, :delivery_dow, :created_at, :sent, :product_orders_attributes
  
  # Validations
  accepts_nested_attributes_for :product_orders, :allow_destroy => true, \
                                :reject_if => proc { |po| po[:quantity].blank? || (!po[:quantity].blank? && po[:quantity].to_i<=0) }
  
  # ElasticSearch Index
  tire do 
    index_name('orders')
    mapping do
      indexes :id,              :type => "integer",   :index => 'not_analyzed', :include_in_all => false
      indexes :invoice_number,  :type => "string",    :index => 'not_analyzed'
      indexes :sent,     		:type => "boolean",   :index => 'not_analyzed'
      indexes :store_name,      :type => "string",    :analyzer => 'snowball',  :as => 'store.name_with_locality'
      indexes :store_id,        :type => 'integer',   :index => 'not_analyzed', :as => 'store[:id]'
      indexes :company_id,      :type => 'integer',   :index => 'not_analyzed', :as => 'store.company[:id]'
      indexes :company_name,    :type => 'string',    :analyzer => 'snowball',  :as => 'store.company[:name]'
      indexes :ship_to_state,   :type => 'string',    :index => 'not_analyzed', :as => 'store.state.state_name'
      indexes :ship_to_state_code, :type => 'string', :index => 'not_analyzed', :as => 'store[:state_code]'
      indexes :deliver_by_day,  :type => 'string',    :index => 'not_analyzed', :as => 'delivery_day_of_the_week'
      indexes :created_at,      :type => 'date',      :index => 'not_analyzed'
      indexes :route_id,        :type => 'integer',   :index => 'not_analyzed'
      indexes :route_name,      :type => 'string',    :index => 'not_analyzed', :as => 'route[:name]'
    end
  end
  # Callbacks  
  before_save do |order|
    # Clean out Product_Orders table to avoid duplication
    ProductOrder.delete_all({:order_id => order[:id]})
    
    # Aggregate duplications coming in from the entry/update form
    # Basic logic - store the index of products within the orders hash in the existing_products hash
    # as the program iterates through the product listing. The key used to store the index is product_<product_id>
    # If a key already exists in the existing_products hash then get the
    # index of the product within the orders hash and update the 
    # quantity to include the quantity specified in the duplicate entry. 
    existing_products = Hash.new
    order.product_orders.each_with_index do |product_order, index|
      key = "product_#{product_order[:product_id]}"
      # Assign the proper volume_unit_id based on the product_category
      product_order[:volume_unit_id] = product_order.product.product_category.volume_unit_id
      
      # Check to see if the product has already been listed in the order
      if existing_products[key].present?
        
        # If it has then get the stored index of the product with the orders hash
        existing_index = existing_products[key]
        
        # Update the quantity for the product within the Orders hash
        order.product_orders[existing_index][:quantity] += product_order[:quantity]
        
        # Delete the duplicate entry
        product_order.delete
      else
        
        # If the product has not yet been listed then add it to the existing_products hash
        existing_products[key] =  index
      end
    end  
    
    # Setting the order sent date
    order[:sent_date] = (order[:sent] ? Date.today : nil) if sent_changed?
  end
  
  def delivery_day_of_the_week
    Date::DAYS_INTO_WEEK.invert[self[:delivery_dow]].to_s.capitalize if Date::DAYS_INTO_WEEK.invert[self[:delivery_dow]]
  end

  def filename
    "OrderforPO_" + (self[:invoice_number].blank? ? 'id_' + self[:id].to_s : self[:invoice_number]).to_s + ".xlsx"
  end

  def organize_products_by_category
    products_by_category = Array.new
    productOrders = self.product_orders
    product_category_ids = productOrders.map{ |product_order| product_order.product[:product_category_id]}.uniq
    
    # Camel case used for productCategories to distinguish it from product_categories association
    productCategories = ProductCategory.find( product_category_ids, :order => :display_order )
    
    productCategories.each do | category |
      element_to_push = Hash.new
      element_to_push[:products] = \
          productOrders.map{ |product_order| product_order if product_order.product[:product_category_id] ==  category[:id] }.compact
      element_to_push[:name] = category[:name]
      products_by_category.push( element_to_push )
    end
    
    return products_by_category
  end


  def self.search_orders( params , per_page = 10, page = 1  )
    store_id = params[:store_id] if params[:store_id].present?
    company_id = params[:company_id] if params[:company_id].present?
    route_id = params[:route_id] if params[:route_id].present?
    state_code = params[:shipping_state] if params[:shipping_state].present?
    sent_status = params[:sent] if params[:sent].present?
  
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

    query = params[:q] if params[:q].present?
    
    tire_order_listing = self.tire.search :per_page => per_page, :page => page do 
      query do
           boolean do
	           # Based on the logic above either both of the dates or at least one of them
	           # one of them will have dates in them or will be set to nil. Hence no defined? check for them.
      	     must { range :created_at, {:gte => start_date } } unless start_date.nil?
      	     must { range :created_at, {:lte => end_date.to_s } } unless end_date.nil?
      	     must { string query } if defined?(query) && query
      	     must { term :store_id,  store_id.to_i } if defined?(store_id) && store_id
      	     must { term :company_id, company_id } if defined?(company_id) && company_id
      	     must { term :ship_to_state_code, state_code } if defined?(state_code) && state_code
      	     must { term :sent, sent_status } if defined?(sent_status) && !sent_status.nil?
           end
      end

      # Filtering for facets
      filter :term, :route_id => route_id             if defined?(route_id) && route_id

      # Defining facets
      if !params[:shipping_state].present?
        facet 'states' do
          terms :ship_to_state_code
        end  
      end
      if !params[:company_id].present?
        facet 'chains' do 
          terms :company_id
        end  
      end
      
      facet 'delivery_day' do
        terms :deliver_by_day
      end
        
      facet 'routes' do
        terms :route_id
      end
	  
  	  facet 'sent' do 
  		  terms :sent
  	  end
      
      sort  {by :created_at, 'desc'} unless params[:sort].present?
    end

    more_pages = (tire_order_listing.total_pages > page )
    
    facets = Hash.new


    # Populating States Facet
    if tire_order_listing.facets['states'] && tire_order_listing.facets['states']['terms'].count > 0
      facets['states'] = []
      tire_order_listing.facets['states']['terms'].each_with_index do |state,index| 
        state[:state_name] = State.find(:first, :conditions => {:state_code => state['term']} )[:state_name]
        facets['states'].push(state)
      end
    end
    
    # Populating Chains Facet
    if tire_order_listing.facets['chains'] && tire_order_listing.facets['chains']['terms'].count > 0
      facets['chains'] = []
      tire_order_listing.facets['chains']['terms'].each_with_index do |chain,index|
        chain[:company_name] = Company.find(chain['term'].to_i)[:name]
        facets['chains'].push(chain)
      end
    end
    
    # Populating Delivery Day Facets
    facets['delivery_day'] = tire_order_listing.facets['delivery_day']['terms'] if tire_order_listing.facets['delivery_day']['terms'].count > 1

    return_value = Hash.new
    return_value[:results] = tire_order_listing
    return_value[:facets] = facets
    return_value[:more_pages] = more_pages
    return_value[:dates] = [start_date,end_date]
    return return_value
  end
end
