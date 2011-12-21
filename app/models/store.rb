class Store < ActiveRecord::Base
  
  belongs_to :company
  belongs_to :division
  belongs_to :state, :foreign_key => [:country, :state_code]
  
  has_many :audits
  has_one :pending_audit, :class_name => "Audit", :conditions => {:status => 0}, :order => "created_at desc"
  has_one :last_audit, :class_name => "Audit", :conditions => {:status => 1}, :order => "created_at desc"

  define_index do
    indexes :name
    indexes city
    indexes state(:state_name), :as => :state_name
    indexes country 
    indexes company(:name), :as => :company_name
    indexes zip

    has :id, created_at, updated_at
  end
 
  before_save do |store|
    store[:name] = store[:name].strip
    store[:street_address] = store[:street_address].strip
    store[:suite] = store[:suite].strip
    store[:city] = store[:city].strip
  end

  def has_pending_audit?
    !pending_audit.blank?
  end
  
  def completed_audits( limit = 25)
    audits.where({:status => 1}).order("created_at desc").limit( limit ).includes(:audit_journal)    
  end
  
  def address
    return_value = self[:street_address].strip.titlecase
    return_value += ", " + self[:suite].strip unless self[:suite].blank?
    return_value += ", " + self[:city].strip.titlecase
    return_value += ", " + self[:state_code]
    return_value += " - " + self[:zip].strip unless self[:zip].blank?
    return_value += "(" + self[:country] + ")" unless self[:country] == "US"
    return return_value
  end
end
