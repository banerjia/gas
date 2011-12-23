class ZipCode < ActiveRecord::Base
  
  set_primary_keys :country, :zip
  
  belongs_to :state, :foreign_key => [:country, :state_code]
  has_many :stores, :foreign_key => [:country, :zip]
  
  def location_in_radians
    self.class.location_in_radians( [self[:lat], self[:lng]] )  
  end
  
  def self.miles_to_m(miles)
    miles * 1.6 * 1000
  end
  
  def self.location_in_radians(lat_long_or_zip, country = 'US')
    
    lat_long_or_zip = \
                      Geokit::Geocoders::GoogleGeocoder.geocode(lat_long_or_zip).ll.split(",").map{|item| item.to_f} \
                      if lat_long_or_zip.class != Array
                        
    lat_long_or_zip.map{|item| item * Math::PI/180}
  end
end