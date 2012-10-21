class ProductCategory < ActiveRecord::Base
  has_many :products, :dependent => :nullify
  belongs_to :volume_unit
  
  attr_accessible :name, :limited_availability
  
  validates :name, :uniqueness => {:message => "Name of the product category should be unique"}, :presence => {:message => "Please provide a product category name"}
  
  before_save {|category| category[:name].upcase!}
  
  def default_volume_unit
    volume_unit
  end
  
  def default_volume_unit=(value)
    self[:volume_unit_id] = value[:id]
  end
  
  def proper_name
    self[:name].titlecase
  end
end
