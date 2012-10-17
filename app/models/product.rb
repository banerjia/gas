class Product < ActiveRecord::Base  
  has_many :product_orders
  
  attr_accessible :name, :code, :active
  
  validates :code, :presence => { :message => 'Required'}, :uniqueness => {:case_sensitive => false, :message => 'Unique'}
end
