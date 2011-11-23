class Company < ActiveRecord::Base
  
  has_many :stores
  has_many :divisions
  has_many :states, :through => :stores, :uniq => :true
  
  validates_presence_of :name
  validates_associated :divisions
  
  attr_accessible :name, :divisions_attributes
  
  accepts_nested_attributes_for :divisions
  
  def states_with_stores
    Store.find(:all,
               :conditions => {:company_id => self[:id]},
               :select => "stores.state_code, state_name, count(id) as `number_of_stores`",
               :order => "stores.country, stores.state_code",
               :group => "stores.country, stores.state_code",
               :joins => :state)
  end
  
end
#"INNER JOIN tblStates ON stores.state_code = tblStates.state_code and stores.country = tblStates.country"