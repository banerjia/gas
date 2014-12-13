class Store < ActiveRecord::Base
  extend ::Geocoder::Model::ActiveRecord   
  include StoreSearchable
  include StoreImport
  
  
  
  # Validations  
  validates_presence_of [:name, :street_address, :city, :state_code]
  
  # Associations
  belongs_to :company, :counter_cache => true
  belongs_to :state, :foreign_key => [:country, :state_code]
  
  belongs_to :region, :counter_cache => true
  
  has_many :store_contacts

  has_many :orders
  
  has_many :audits
	has_one :last_audit, -> { where("status=1").order("created_at desc") }, :class_name => "Audit"
  has_one :pending_audit, -> { where "status = 0"}, :class_name => "Audit"

  accepts_nested_attributes_for   :store_contacts, :allow_destroy => true, :reject_if => proc { |sc| sc[:name].blank? }
  accepts_nested_attributes_for   :region, :reject_if => proc {|r| r[:name].blank? }
                              
  


  geocoded_by :address
  
  after_validation :geocode

  def has_pending_audit?
    !pending_audit.blank?
  end

  def completed_audits( limit = "0,25")
    audits.where({:status => 1}).order("created_at desc").limit( limit ).includes(:audit_journal)    
  end
  
  def address
    Store.address( self )
  end
  
  def self.address(storeObject)
    return_value = storeObject[:street_address].strip.titlecase
    return_value += ", " + storeObject[:suite].strip unless storeObject[:suite].blank?
    return_value += ", " + storeObject[:city].strip.titlecase
    return_value += ", " + storeObject[:state_code]
    return_value += " - " + storeObject[:zip].strip unless storeObject[:zip].blank?
    return_value += " (" + storeObject[:country] + ")" unless storeObject[:country] == "US"
    return return_value
  end
  
  def full_name
    return_value = self[:name]
    return_value += " Store# #{self[:store_number]}" unless self[:store_number].blank?
    return_value += " (#{self[:locality]})" unless self[:locality].blank?
    return return_value    
  end
  
  def self.update_geolocation
    stores_to_update = Store.where("latitude IS NULL OR longitude IS NULL")
    stores_to_update.each_with_index do |store, index|
      lat_lng = Location.get_geolocation( store.address )
      lat_lng = Location.get_geolocation( store[:zip] ) if lat_lng==[nil,nil]
      store[:latitude] = lat_lng[0]
      store[:longitude] = lat_lng[1]
      store.update_columns({:latitude => lat_lng[0], :longitude => lat_lng[1]})
      sleep(1) if (index%10) == 0
    end
  end

  def as_indexed_json(options={})
    self.as_json({
      only: [:id, :country, :state_code],
      methods: [:address, :full_name],
      include: {
        company: { only: [:id, :name] },
        state: { only: :state_name },
        last_audit: {only: [:id, :created_at, :score]},
        region: {only: [:id, :name]}
      }
    })
  end
  
  def self.index_refresh
    Store.__elasticsearch__.client.indices.delete index: Store.index_name rescue nil
    Store.__elasticsearch__.client.indices.create index: Store.index_name, body: { settings: Store.settings.to_hash, mappings: Store.mappings.to_hash}
    Store.import
  end
end

