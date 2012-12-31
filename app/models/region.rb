class Region < ActiveRecord::Base  
  belongs_to :company, :counter_cache => true
  
  has_many :stores
end