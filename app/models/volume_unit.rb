class VolumeUnit < ActiveRecord::Base
    
  attr_accessible :name
  
  has_many :product_orders
end
