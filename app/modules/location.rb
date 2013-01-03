module Location
  def self.miles_to_m(miles)
    miles * 1.6 * 1000
  end

  def self.get_geolocation( address ) 
   lat_lng = nil
   begin
      geoloc = Geokit::Geocoders::GoogleGeocoder.geocode(address)
      lat_lng = [geoloc.lat,geoloc.lng] 
   rescue 
      lat_lng = [nil,nil]
   end

   return lat_lng
  end

  def self.get_lat_lng( store ) 
    if store[:zip].blank?
        geoloc = Geokit::Geocoders::GoogleGeocoder.geocode(store.address)
        store[:zip] = geoloc.zip unless geoloc.zip.blank?
      else
        geoloc = Geokit::Geocoders::GoogleGeocoder.geocode(store[:zip] + ', ' + store[:country])
      end
      
      lat_lng = [geoloc.lat,geoloc.lng] 
  end
end
