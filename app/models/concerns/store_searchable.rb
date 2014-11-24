module StoreSearchable
  extend ActiveSupport::Concern

  included do
    include Elasticsearch::Model
    include Elasticsearch::Model::Callbacks


    settings do
      index_name    "graeters-#{Rails.env}"
    	mapping do 
    		indexes :id, :type => 'integer', :index => 'not_analyzed'
        indexes :company_id, :type => 'integer', :index => 'not_analyzed'
        indexes :region_id, :type => 'integer', :index => 'not_analyzed'
        indexes :name, :type => 'string', :analyzer => 'standard'
    		indexes :locality, :type => 'string', :analyzer => 'standard'
    		indexes :street_address, :type => 'string', :analyzer => 'standard'
    		indexes :zip, :type => 'string', :index => 'not_analyzed'
    		indexes :city, :type => 'string', :index => 'not_analyzed'
        indexes :state_code, :type => "string", :index => 'not_analyzed'
        indexes :country, :type => "string", :index => 'not_analyzed'
        indexes :state do 
          indexes :state_name, :type => 'string', :index => 'not_analyzed'
        end  		
        indexes :region do 
          indexes :name, :type => 'string', :analyzer => 'standard'
        end
        
        indexes :company do
          indexes :name, :type => 'string', :analyzer => 'standard'
        end
        
        indexes :region do
          indexes :name, :type => 'string', :analyzer => 'standard'
        end
        
        indexes :last_audit do
          indexes :score, :type => 'integer', :index => 'not_analyzed'
          indexes :created_at, :type => 'date', :index => 'not_analyzed'
        end
    	end
    end
  

    def self.search( params )
      facets = Hash.new    
      return_value = Hash.new
      page = (params[:page] || 1).to_i
      size = (params[:per_page] || 10).to_i
      offset = (page - 1) * size
      
      bool_array_must = []
      
      bool_array_must.push( {term: {company_id: params[:company_id]}}) if params[:company_id].present?
      bool_array_must.push( {term: {state_code: params[:state]}}) if params[:state].present?
    
      es_results = Store.__elasticsearch__.search :size => size, :from => offset, :query =>
      {
        bool:
        {
          must: bool_array_must
        }
      },
      :sort => 
        [
          {:state_code => {order:"asc"}},
          {:name_with_locality => {order:"asc"}}
        ]
      
      
#      do 
#        query do
#          boolean do
            #must { string params[:q]} if params[:q].present?
            #must { string "state:#{params[:state]}" } if params[:state].present?
#            must :term, :company_id => params[:company_id] if params[:company_id].present?
#          end
#        end
      
#        filter :term, :region_id => params[:region] if params[:region].present?

#        facet 'regions' do 
#          terms :region_id, :order => 'term'
#        end     
      
#        sort  {by :name_sort} 
#      end

      # Populating Regions Facet
      
      #if results.facets['regions']['terms'].count > 0
      #  facets['regions'] = []
      #  results.facets['regions']['terms'].each_with_index do |region,index| 
      #    region[:region_name] = Region.find(region['term'] )[:name]
      #    facets['regions'].push(region)
      #  end
      #end
      
    

      return_value[:more_pages] = ((es_results.results.total.to_f / size.to_f) > page.to_f )
      return_value[:results] = es_results.results.map { |item| item._source.merge({ :id => item[:_id].to_i}) }
      #return_value[:facets] = facets
      return_value[:total] = es_results.results.total

    
      return return_value
    end
  end
end