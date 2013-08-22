class Company < ActiveRecord::Base
  has_many :stores
  has_many :states, :through => :stores, :uniq => :true
  
  has_many :regions
  
  validates_presence_of :name, \
                        :message => "Company name cannot be blank. Please provide a company name."
  
  HUMANIZED_ATTRIBUTES = {
    :name => "Company name"
  }
  
  def self.human_attribute_name(attr, options = {})
    HUMANIZED_ATTRIBUTES[attr.to_sym] || super
  end
  
  def states_with_stores
    Store.find(:all,
               :conditions => {:company_id => self[:id]},
               :select => "stores.country, stores.state_code, state_name, count(id) as `stores_count`",
               :order => "stores.country, stores.state_code",
               :group => "stores.country, stores.state_code",
               :joins => :state)
  end
  
end
