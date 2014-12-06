class Store < ActiveRecord::Base
  include StoreSearchable
  include StoreImport
  
  # Validations
  
  validates_presence_of [:name, :street_address, :city, :state]
  
  # Associations
  belongs_to :company, :counter_cache => true
  belongs_to :state, :foreign_key => [:country, :state_code]
  
  belongs_to :region, :counter_cache => true
  
  has_many :store_contacts

  has_many :orders
  
  has_many :audits
	has_one :last_audit, -> { where("status=1").order("created_at desc") }, :class_name => "Audit"
  has_one :pending_audit, -> { where "status = 0"}, :class_name => "Audit"

  accepts_nested_attributes_for :store_contacts, :allow_destroy => true, \
                                :reject_if => proc { |sc| sc[:name].blank? }
  

  # Callbacks
  before_save do |store|
    # Updating StoreContacts
    StoreContact.delete_all({:store_id => store[:id]})
    
    # Region Changes    
    if region_id_changed?
      Region.decrement_counter( :stores_count, store.region_id_was) if store.region_id_was
      Region.increment_counter( :stores_count, store[:region_id]) if store[:region_id]
    end
    
    # Address Changes
    #store[:name] = store[:name].strip
    store[:street_address] = store[:street_address].strip
    store[:suite] = store[:suite].strip if store[:suite]
    store[:city] = store[:city].strip
    
    # Only populate the longitude and latitude information if 
    # the zipcode has changed
    if zip_changed?
      
      # If zip code has been left blank, attempt to fetch it
      # using Geokit.
      # If not fetch the location information based on
      # zip code and country
      if store[:zip].blank?
        geoloc = Geokit::Geocoders::GoogleGeocoder.geocode(store.address)
        store[:zip] = geoloc.zip unless geoloc.zip.blank?
      else
        geoloc = Geokit::Geocoders::GoogleGeocoder.geocode(store[:zip] + ', ' + store[:country])
      end
          
      
      # Populate the fields with this value              
      store[:latitude] = geoloc.lat
      store[:longitude] = geoloc.lng  
    end
  end

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
  
  def name_with_locality
    return_value = self[:name]
    return_value += " (#{self[:locality]})" unless self[:locality].blank?
    return return_value    
  end
  
  def self.update_geolocation
    stores_to_update = find(:all, :conditions => "latitude IS NULL OR longitude IS NULL")
    stores_to_update.each_with_index do |store, index|
      lat_lng = Location.get_geolocation( store.address )
      lat_lng = Location.get_geolocation( store[:zip] ) if lat_lng==[nil,nil]
      store[:latitude] = lat_lng[0]
      store[:longitude] = lat_lng[1]
      store.save
      sleep(1) if (index%10) == 0
    end
  end

  def as_indexed_json(options={})
    self.as_json({
      only: [:locality, :name, :company_id, :region_id, :country, :state_code],
      methods: [:address, :name_with_locality],
      include: {
        company: { only: :name },
        state: { only: :state_name },
        last_audit: {only: [:created_at, :score]},
        region: {only: :name}
      }
    })
  end
  
  def self.index_refresh
    Store.__elasticsearch__.client.indices.delete index: Store.index_name rescue nil
    Store.__elasticsearch__.client.indices.create index: Store.index_name, body: { settings: Store.settings.to_hash, mappings: Store.mappings.to_hash}
    Store.import
  end
end

