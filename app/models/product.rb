class Product < ActiveRecord::Base  
  has_many :product_orders
  belongs_to :product_category
  
  #validates :name, :uniqueness => { :message => "A product with a similar name already exists" }, :presence => { :message => "Please specify a name for this product"}
  validates :code, :presence => { :message => 'Required'}, :uniqueness => {:case_sensitive => false, :message => 'Unique'}
  
  before_save do |product|
    product.attributes.each  do |attr_name,attr_value| 
      product[attr_name].strip! if Product.columns_hash[attr_name].type == :string && !product[attr_name].nil?
      product[attr_name] = nil if attr_value.blank?
    end
    product[:code].upcase!
  end
  
  def availability
    self[:from] + " - " + self[:till]    
  end
  
  def self.update_sort_order
    update_seq = [3,4,[25,26,28,29,30],5,6,7,8,9,10,11,12,15,17,13,23,38,14,21,40,42,43,39,18,16,44,19,20,41,24,33,27,34,31,32,33]
    update_seq.each_with_index do |product_id, index| 
      Product.where(:id => product_id).update_all(:sort_order_for_order_sheet => index+1)
    end
  end
end
