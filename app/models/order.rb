class Order < ActiveRecord::Base
  include OrderSearchable
  include OrderImport

  Order.__elasticsearch__.client = Elasticsearch::Client.new host:  ENV["es_host"]
  
  # Associations
  has_many :product_orders, dependent: :destroy
  has_many :products, through: :product_orders
  has_many :product_categories, -> { group :product_category_id },  through: :products #, group: :product_category_id
  belongs_to :route
  
  belongs_to :store, counter_cache: true
  
  # Validations
  validates :store, presence: {message: "Please select a store"}
  validates :product_orders, presence: {message: "Orders require one or more products to be listed"}
  accepts_nested_attributes_for :product_orders, allow_destroy: true, \
                                reject_if: proc { |po| po[:quantity].blank? || po[:quantity].to_i.zero? }
  

  # Callbacks  

  before_save on: [:create, :update] do |order|
    # Setting the order sent date
    if email_sent_changed? || email_sent_date_changed?
    	order[:email_sent_date] = (order[:email_sent] ? Date.today : nil) if email_sent_changed? && order[:email_sent_date].nil?

    # Do not do updates if only email_sent is changed
    # because it can only be changed from the mailer
    # script and that does not change any other part of an order
    	return 
    end

    # Clean out Product_Orders table to avoid duplication
    ProductOrder.delete_all({order_id: order[:id]})
    
    # Assign the appropriate volume_unit_id to each entry
    order.product_orders.each do |po|
      po[:volume_unit_id] = po.product.product_category.volume_unit_id
    end    
  end
  
  def delivery_day_of_the_week
    Date::DAYS_INTO_WEEK.invert[self[:delivery_dow]].to_s.capitalize if Date::DAYS_INTO_WEEK.invert[self[:delivery_dow]]
  end

  def filename
    "Order_" + (self[:invoice_number].blank? ? 'id_' + self[:id].to_s : self[:invoice_number]).to_s + ".xlsx"
  end

  def organize_products_by_category
    products_by_category = Array.new
    productOrders = self.product_orders.includes(:product)
    product_category_ids = productOrders.map{ |product_order| product_order.product[:product_category_id]}.uniq
    
    # Camel case used for productCategories to distinguish it from product_categories association
    productCategories = ProductCategory.order(:display_order ).find( product_category_ids)
    
    productCategories.each do | category |
      element_to_push = Hash.new
      element_to_push[:products] = \
          productOrders.map{ |product_order| product_order if product_order.product[:product_category_id] ==  category[:id] }.compact
      element_to_push[:products] = element_to_push[:products].sort{ |a,b| a.product[:sort_order_for_order_sheet] <=> b.product[:sort_order_for_order_sheet]}
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
