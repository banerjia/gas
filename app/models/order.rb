class Order < ActiveRecord::Base
  
  # Associations
  has_many :product_orders, :dependent => :destroy
  has_many :products, :through => :product_orders
  has_many :product_categories, :through => :products, :group => :product_category_id
  
  belongs_to :store, :counter_cache => true
  
  # Attributes
  attr_accessible :invoice_number, :invoice_amount, :route_number, :delivery_date, :fulfilled, :created_at, :product_orders_attributes
  
  # Validations
  accepts_nested_attributes_for :product_orders, :allow_destroy => true, \
                                :reject_if => proc { |po| po[:quantity].blank? || (!po[:quantity].blank? && po[:quantity].to_i<=0) }
  
  # Callbacks
  before_update do |order|
    ProductOrder.delete_all({:order_id => order[:id]})
  end
end