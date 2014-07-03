module StoreSearchable
  extend ActiveSupport::Concern

  included do
    include Elasticsearch::Model
    include Elasticsearch::Model::Callbacks


    settings do
      index_name    "stores-#{Rails.env}"
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
          terms :region_id, :order => 'term'
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
  end
end