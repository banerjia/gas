class Division < ActiveRecord::Base

  belongs_to :company, :counter_cache => true
  has_many :stores

  validates_presence_of :name
  validates_uniqueness_of :name, :scope => :company_id, \
                          :message => "Division name already exists. Please choose a different name."

  attr_accessible :name, :company_id

  after_save :update_store_counts

  HUMANIZED_ATTRIBUTES = {
    :name => "Division name"
  }

  def self.human_attribute_name(attr, options={})
    HUMANIZED_ATTRIBUTES[attr.to_sym] || super
  end

  def update_store_counts
    if company_id_changed?
      Store.update_all({:company_id => self[:company_id]},{:company_id => company_id_was, :division_id => self[:id]})
      Company.update_counters company_id_was, :stores_count => (-1)*self[:stores_count]
      Company.update_counters self[:company_id], :stores_count => self[:stores_count]      
    end
  end
end