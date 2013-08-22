class Product < ActiveRecord::Base  
  has_many :product_orders
  belongs_to :product_category
  
  #validates :name, :uniqueness => { :message => "A product with a similar name already exists" }, :presence => { :message => "Please specify a name for this product"}
  validates :code, :presence => { :message => 'Required'}, :uniqueness => {:case_sensitive => false, :message => 'Unique'}
  
  before_save do |product|
    product.attributes.each  do |attr_name,attr_value| 
      product[attr_name].strip! unless Product.columns_hash[attr_name].type != :string
      product[attr_name] = nil if attr_value.blank?
    end
    product[:code].upcase!
  end
  
  def availability
    self[:available_from] + " - " + self[:available_till]    
  end
end
