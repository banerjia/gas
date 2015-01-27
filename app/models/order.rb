class Order < ActiveRecord::Base
  include OrderSearchable
  include OrderImport
  
  # Associations
  has_many :product_orders, :dependent => :destroy
  has_many :products, :through => :product_orders
  has_many :product_categories, -> { group :product_category_id },  :through => :products #, :group => :product_category_id
  belongs_to :route
  
  belongs_to :store, :counter_cache => true
  
  # Validations
  accepts_nested_attributes_for :product_orders, :allow_destroy => true, \
                                :reject_if => proc { |po| po[:quantity].blank? || (!po[:quantity].blank? && po[:quantity].to_i.zero?) }
  

  # Callbacks  
  before_save do |order|
    # Setting the order sent date
    if email_sent_changed? || email_sent_date_changed?
    	order[:email_sent_date] = (order[:email_sent] ? Date.today : nil) if email_sent_changed? && order[:email_sent_date].nil?

    # Do not do updates if only email_sent is changed
    # because it can only be changed from the mailer
    # script and that does not change any other part of an order
    	return
    end

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

  def as_indexed_json(options={})
    self.as_json({
      only: [:id, :invoice_number, :email_sent, :created_at],
      methods: [:delivery_day_of_the_week],
      include: {
        store: { 
          only: [:id, :state_code], 
          methods: [:full_name],
          include: {
            company: { only: [:id, :name]},
            state: { only: [:state_name]}
          }
        },
        route: {
          only: [:id, :name]
        }
      }
    })
  end  

  def self.index_refresh
    Order.__elasticsearch__.client.indices.delete index: Order.index_name rescue nil
    Order.__elasticsearch__.client.indices.create index: Order.index_name, body: { settings: Order.settings.to_hash, mappings: Order.mappings.to_hash}
    Order.import
  end
end
