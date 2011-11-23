class Division < ActiveRecord::Base
  
  belongs_to :company, :counter_cache => true
  has_many :stores
  
  validates_presence_of :name
  
  attr_accessible :name, :company_id
  
  after_save :update_store_counts
  
  def update_store_counts
    if company_id_changed?
      Store.update_all({:company_id => self[:company_id]},{:company_id => company_id_was, :division_id => self[:id]})
      Company.update_counters company_id_was, :stores_count => (-1)*self[:stores_count]
      Company.update_counters self[:company_id], :stores_count => self[:stores_count]      
    end
  end
end