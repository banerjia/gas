class ProductOrder < ActiveRecord::Base
  self.primary_keys = [:order_id, :product_id]
  
  #default_scope :include => :volume_unit
  
  belongs_to :product
  belongs_to :order
  belongs_to :volume_unit
  
  def sleeves 
    (self[:quantity] * self.volume_unit[:sleeve_conversion]).to_i
  end
end
