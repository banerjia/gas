class ProductCategory < ActiveRecord::Base
  has_many :products, :dependent => :nullify
  has_many :product_orders, :through => :products
#  belongs_to :volume_unit
  
  validates :name, :uniqueness => {:message => "Name of the product category should be unique"}, :presence => {:message => "Please provide a product category name"}
  
  before_save {|category| category[:name].upcase!}
  
  def proper_name
    self[:name].titlecase
  end

  def self.for_select
  	product_categories_with_current_products = Product.where(\
  		["`active` = 1 AND (`from` IS NULL OR `from` <= :today) AND (`till` IS NULL OR `till` >= :today)", {today: Date.today.to_date}] \
  	).pluck(:product_category_id)
  	self.order(:display_order).find(product_categories_with_current_products)
  end

  def current_products
  	products.where(\
  		["`active` = 1 AND (`from` IS NULL OR `from` <= :today) AND (`till` IS NULL OR `till` >= :today)", {today: Date.today.to_date}] \
  	).order(:sort_order_for_order_sheet)
  end
end
