module Api
  module V1
    class StoresController < ApiController
      
      def search    
      	distance = params[:d]
      	longitude = params[:lon]
      	latitude = params[:lat]

      	stores_found = Store.search( { distance: distance, lon: longitude, lat: latitude})

        render json: stores_found[:results]
      end
    end
  end
end