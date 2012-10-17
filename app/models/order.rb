class Order < ActiveRecord::Base
  attr_accessible :delivery_date, :fulfilled, :product_orders
  
  has_many :product_orders, :dependent => :destroy
  has_many :products, :through => :product_orders
  
  belongs_to :store, :counter_cache => true
end
