class Store < ActiveRecord::Base
  
  belongs_to :company
  belongs_to :state, :foreign_key => [:country, :state_code]
  
  has_many :audits
  has_one :pending_audit, :class_name => "Audit", :conditions => {:status => 0}, :order => "created_at desc"
  has_one :last_audit, :class_name => "Audit", :conditions => {:status => 1}, :order => "created_at desc"

  define_index do
    indexes :name, :sortable => true
    indexes street_address
    indexes store_number
    indexes city, :sortable => true
    indexes state_code, :sortable => true
    indexes country, :sortable => true
    indexes state(:state_name), :as => :state_name, :sortable => true, :facet => true
    indexes company(:name), :as => :company_name, :facet => true
    indexes zip

    # id is symbolised because it's  a Sphinx keyword
    has :id, created_at, updated_at, latitude, longitude, company_id
    #set_property :delta => true
  end
 
  before_save do |store|
    store[:name] = store[:name].strip
    store[:street_address] = store[:street_address].strip
    store[:suite] = store[:suite].strip
    store[:city] = store[:city].strip
    
    # SUGGESTION: Move this section within a Rake task
    # as it communicates with Google Maps API.
    
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
end
