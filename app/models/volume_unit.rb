class VolumeUnit < ActiveRecord::Base
    
  attr_accessible :name, :unit_code, :multiplier
  
  has_many :product_orders
end
