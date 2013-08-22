class ProductCategory < ActiveRecord::Base
  has_many :products, :dependent => :nullify
  has_many :product_orders, :through => :products
#  belongs_to :volume_unit
  
  validates :name, :uniqueness => {:message => "Name of the product category should be unique"}, :presence => {:message => "Please provide a product category name"}
  
  before_save {|category| category[:name].upcase!}
  
  def proper_name
    self[:name].titlecase
  end
end
