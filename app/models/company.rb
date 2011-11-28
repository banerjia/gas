class Company < ActiveRecord::Base
  
  has_many :stores
  has_many :divisions
  has_many :states, :through => :stores, :uniq => :true
  
  validates_presence_of :name
  validates_associated :divisions
  
  attr_accessible :name, :divisions_attributes
  
  accepts_nested_attributes_for \
      :divisions, :reject_if => lambda { |a| a[:name].blank? }, :allow_destroy => true
  
  def states_with_stores
    Store.find(:all,
               :conditions => {:company_id => self[:id]},
               :select => "stores.country, stores.state_code, state_name, count(id) as `number_of_stores`",
               :order => "stores.country, stores.state_code",
               :group => "stores.country, stores.state_code",
               :joins => :state)
  end
  
  def has_divisions?
    self.divisions.size > 0
  end
  
  def has_stores_without_division?
    return self.has_divisions? && self.divisions.sum(:stores_count)!=self.stores.size
  end
  
end