class StoreContact < ActiveRecord::Base
  
  attr_accessible :store_id, :name, :title, :phone, :email
  
  belongs_to :store
end
