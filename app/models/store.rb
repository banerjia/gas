class Store < ActiveRecord::Base
  include StoreSearchable
  include StoreImport
  
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
      
      # Once geolocation information has been retrieved
      # determine the lat and long values in radians.
      lat_lng = ZipCode.location_in_radians( \
                  geoloc.ll.split(",").map{|item| item.to_f} \
                  )     
      
      # Populate the fields with this value              
      store[:latitude] = lat_lng[0]
      store[:longitude] = lat_lng[1]   
    end
  end

  def has_pending_audit?
    !pending_audit.blank?
  end

  def completed_audits( limit = "0,25")
    audits.where({:status => 1}).order("created_at desc").limit( limit ).includes(:audit_journal)    
  end
  
  def address
    return_value = self[:street_address].strip.titlecase
    return_value += ", " + self[:suite].strip unless self[:suite].blank?
    return_value += ", " + self[:city].strip.titlecase
    return_value += ", " + self[:state_code]
    return_value += " - " + self[:zip].strip unless self[:zip].blank?
    return_value += " (" + self[:country] + ")" unless self[:country] == "US"
    return return_value
  end
  
  def name_with_locality
    return_value = self[:name]
    return_value += " (#{self[:locality]})" unless self[:locality].blank?
    return return_value    
  end
  
  def name
    return_value = self[:name]
    return_value += " (#{self[:locality]})" unless self[:locality].blank?
    return {:original => self[:name], :name_with_locality => return_value }
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
      only: [:locality, :store_address, :zip, :city, :state_code, :company_id, :region_id],
      methods: [:name],
      include: {
        company: { only: :name },
        state: { only: :state_name }
      }
    })
  end
end
