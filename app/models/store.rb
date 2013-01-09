class Store < ActiveRecord::Base
  include Tire::Model::Search
  include Tire::Model::Callbacks
  
  belongs_to :company, :counter_cache => true
  belongs_to :state, :foreign_key => [:country, :state_code]
  
  belongs_to :region, :counter_cache => true

  has_many :orders
  
  has_many :audits
  has_one :pending_audit, :class_name => "Audit", :conditions => {:status => 0}, :order => "created_at desc"
  has_one :last_audit, :class_name => "Audit", :conditions => {:status => 1}, :order => "created_at desc"

  tire do 
  	index_name('stores')
  	mapping do 
  		indexes :id, :type => 'integer', :index => 'not_analyzed', :include_in_all => false
  		indexes :name, :type => 'string', :analyzer => 'snowball'
  		indexes :locality, :type => 'string', :analyzer => 'snowball'
  		indexes :name_sort, :type => 'string', :index => 'not_analyzed', :include_in_all => false, :as => 'name_with_locality'
  		indexes :store_address, :type => 'string', :as => 'address', :analyzer => 'snowball'
  		indexes :zip, :type => 'string', :index => 'not_analyzed', :include_in_all => false
  		indexes :city, :type => 'string', :index => 'not_analyzed', :include_in_all => false
  		indexes :state, :type => 'string', :index=> 'not_analyzed', :include_in_all => false, :as => 'state_code'
  		indexes :country, :type => 'string', :index => 'not_analyzed', :include_in_all => false
  		indexes :state_name, :type => 'string', :as => 'state.state_name', :analyzer => 'snowball'
  		indexes :company_id, :type => 'integer', :index => 'not_analyzed', :include_in_all => false
  		indexes :region_name, :type => 'string', :analyzer => 'snowball'
  		indexes :region_id, :type => 'integer', :index => 'not_analyzed', :include_in_all => false
  	end
  end
  
  def self.search( params )
    facets = Hash.new    
    return_value = Hash.new
    page = (params[:page] || 1).to_i
    
    results = tire.search :load => {:include => ['company', 'last_audit']}, :per_page => params[:per_page], :page => page do 
      query do
        boolean do
          must { string params[:q]} if params[:q].present?
          must { string "state:#{params[:state]}" } if params[:state].present?
          must { string "company_id:#{params[:company_id]}" } if params[:company_id].present?
        end
      end
      
      filter :term, :region_id => params[:region] if params[:region].present?

      facet 'regions' do 
        terms :region_id
      end     
      
      sort  {by :name_sort} 
    end

    # Populating Regions Facet
    if results.facets['regions']['terms'].count > 0
      facets['regions'] = []
      results.facets['regions']['terms'].each_with_index do |region,index| 
        region[:region_name] = Region.find(region['term'] )[:name]
        facets['regions'].push(region)
      end
    end
    
    return_value[:more_pages] = (results.total_pages > page )
    return_value[:results] = results
    return_value[:facets] = facets
    return_value[:total] = results.total
    
    return return_value
  end

  before_save do |store|
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

  def region_name
    return_value = nil
    return_value = self.region[:name] if self.region
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
end
