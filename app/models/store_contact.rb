class StoreContact < ActiveRecord::Base
  self.primary_keys = [:store_id, :email]
  
  belongs_to :store
end
