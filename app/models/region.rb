class Region < ActiveRecord::Base  
  
  validates :name, :uniqueness => {:scope => :company_id ,:case_sensitive => false}
  
  belongs_to :company, :counter_cache => true
  
  has_many :stores
end