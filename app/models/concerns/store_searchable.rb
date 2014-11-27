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
			indexes :name, type: 'multi_field'	do 
				indexes :name
				indexes :raw, :index => 'not_analyzed'
			end
			#, :type => 'string', :analyzer => 'standard'
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
				indexes :name, :type => 'multi_field' do
					indexes :name
					indexes :raw, :index => 'not_analyzed'
				end
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
      query_string = {match_all:{}}
      
      bool_array_must.push( {term: {company_id: params[:company_id]}}) if params[:company_id].present?
      bool_array_must.push( {term: {state_code: params[:state]}}) if params[:state].present?
      bool_array_must.push( {term: {country: params[:country]}}) if params[:country].present?
      bool_array_must.push({term: {region_id: params[:region]}}) if params[:region].present?
      query_string = {query_string: {query: params[:q]}} if params[:q].present?
    
      es_results = __elasticsearch__.search :size => size, :from => offset, 
      :query => query_string,
      :filter => {
        :bool => {
          must: bool_array_must
        }
      },
  	  :aggs => {
    		:regions => {
    			:terms => {
    				field: "region_id"
    			},
    			:aggs => {
    				:region_names => {
    					:terms => {
    						field: "region.name.raw"
    					}
    				}
    			}
    		}
  	  },
      :sort => [
        {:_score => {order: "desc"}},
        {:state_code => {order:"asc"}},
        {:name_with_locality => {order:"asc"}}
      ]
      
    

      return_value[:more_pages] = ((es_results.results.total.to_f / size.to_f) > page.to_f )
      return_value[:results] = es_results.results.map { |item| item._source.merge({ :id => item[:_id].to_i}) }
      if es_results.response['aggregations'].present?
        return_value[:aggs] = {}
        return_value[:aggs][:regions] = es_results.response['aggregations']['regions']['buckets'].map{ |item| {region_id: item['key'], name: item['region_names']['buckets'].first['key'], found: item['doc_count']}}.sort_by{ |item| item[:name]}  if es_results.response['aggregations']['regions']['buckets'].size > 0
      end
      return_value[:total] = es_results.results.total
      
      return_value[:search_string] = es_results.search.definition[:body] if !Rails.env.production?
      
      return return_value
    end
  end
end