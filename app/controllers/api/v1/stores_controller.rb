module Api
  module V1
    class StoresController < ApiController
      
      def search
        # List keys to be sent in the result set for API calls 
        # to reduce the amount transferred
        safe_keys = [:results, :per_page, :page, :more_pages, :total]

        # Default value of result set size is 5 for API calls
        params[:per_page] = params[:per_page] || 5

      	stores_found = Store.search( params )
        
        # Clearing the keys that are not required in the result set
        stores_found.each do |k,v|
          stores_found.delete(k) unless safe_keys.include? k
        end

        render json: stores_found
      end
    end
  end
end