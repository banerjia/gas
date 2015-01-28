module StoreSearchable
  extend ActiveSupport::Concern

  included do
    include Elasticsearch::Model
    include Elasticsearch::Model::Callbacks


    settings do
		  index_name    "graeters-#{Rails.env}-stores"
			mapping do 
				indexes :id, type: 'integer', index: 'not_analyzed'
  			indexes :full_name, type: 'multi_field'	do 
  				indexes :full_name
  				indexes :raw, index: 'not_analyzed'
  			end
        indexes :address, type: 'string', analyzer: 'standard'
        indexes :store_number, type: 'string', index: 'not_analyzed'
        indexes :location, type: 'geo_point' 
  			indexes :state_code, type: "string", index: 'not_analyzed'
  			indexes :country, type: "string", index: 'not_analyzed'
  			indexes :state do 
  			  indexes :state_name, type: 'string', index: 'not_analyzed'
  			end
			
  			indexes :company do
          indexes :id, type:'integer', index: 'not_analyzed'
  			  indexes :name, type: 'string', analyzer: 'standard'
  			end
			
  			indexes :region do
  				indexes :name, type: 'multi_field' do
  					indexes :name
  					indexes :raw, index: 'not_analyzed'
  				end
  			end
			
  			indexes :last_audit do
          indexes :id, type:'integer', index: 'not_analyzed'
          indexes :score do 
            indexes :base, type: 'integer', index: 'not_analyzed'
            indexes :loss, type: 'integer', index: 'not_analyzed'
            indexes :bonus, type: 'integer', index: 'not_analyzed'
            indexes :total, type: 'integer', index: 'not_analyzed'
          end
  			  indexes :created_at, type: 'date', index: 'not_analyzed'
  			end
  		end
    end
  

    def self.search( params )
      facets = Hash.new    
      return_value = Hash.new
      page = (params[:page] || 1).to_i
      size = (params[:per_page] || 10).to_i
      offset = (page - 1) * size
      include_distance_in_result = (params[:lat].present? && params[:lon].present?)
      
      query_bool_array_must = []
      filter_bool_array_must = []

      # This is the default bool array setting for queries.
      # If no other query parameters are provided then 
      # this will push the query through. On the other 
      # hand if there are other query parameters add to the
      # array then this item is popped off the array. 
      query_bool_array_must.push({constant_score: {filter: { match_all:{}}}})

      # TO DO: Implement functionality to have only certain fields returned in the query set. 
      fields = {}

      sort_array = [
        {_score: {order: "desc"}},
        {state_code: {order:"asc"}},
        {full_name: {order:"asc"}}
      ]
      

      query_bool_array_must.push( {term: {"company.id" => params[:company_id]}}) if params[:company_id].present?
      query_bool_array_must.push( {term: {state_code: params[:state]}}) if params[:state].present?
      query_bool_array_must.push( {term: {country: params[:country]}}) if params[:country].present?
      query_bool_array_must.push({term: {"region.id" => params[:region]}}) if params[:region].present?

      query_bool_array_must.push({query_string: {query: params[:q]}}) if params[:q].present? && !params[:q].blank?
 
      if query_bool_array_must.size > 1
        # If query_bool_array_must.size > 1 => there are other
        # query parameters provided for the query. So pop-off the
        # default match_all criteria that was added earlier on.
        query_bool_array_must.delete_at(0) if query_bool_array_must.size > 1

        # Rearranging the object to look like a BOOL query object
        query_bool_array_must = {bool: {must: query_bool_array_must}}
      else
        query_bool_array_must = query_bool_array_must[0]
      end


      # Construct Filter Bool Array
      filter_bool_array_must.push( {term: {"company.id" => params[:_company_id]}}) if params[:_company_id].present?
      filter_bool_array_must.push( {term: {state_code: params[:_state]}}) if params[:_state].present?
      filter_bool_array_must.push( {term: {country: params[:_country]}}) if params[:_country].present?
      filter_bool_array_must.push({term: {"region.id" => params[:_region]}}) if params[:_region].present?
      if params[:distance].present?
        filter_bool_array_must.push({
          geo_distance: {
            distance: params[:distance],
            location: {
              lat: params[:lat],
              lon: params[:lon]
            }
          }
        })
      end
      if include_distance_in_result
        sort_array.unshift({
            _geo_distance: {
              location: {
                lat: params[:lat],
                lon: params[:lon]
              },
              order: "asc",
              unit: "mi"
            }
          })
      end
    
      es_results = __elasticsearch__.search size: size, from: offset, 
      query: query_bool_array_must,
      filter: {
        bool: {
          must: filter_bool_array_must
        }
      },
      aggs: {
        regions: {
          terms: {
            field: "region.id"
          },
          aggs: {
            region_names: {
              terms: {
                field: "region.name.raw"
              }
            }
          }
        },
        states: {
          terms: {
            field: "state_code"
          },
          aggs: {
            state_names: {
              terms: {
                field: "state.state_name"
              }
            }
          }
        } 
      },
      sort: sort_array      
    

      return_value[:more_pages] = ((es_results.results.total.to_f / size.to_f) > page.to_f )
      return_value[:page] = page
      return_value[:per_page] = size
      return_value[:results] = es_results.results.map do |item|
        retval = nil
        if !fields.empty?
          retval = item.fields
        else
          retval = item._source
        end
        retval.merge({ id: item[:_id].to_i}).merge((include_distance_in_result ? {distance: item[:sort].first} : {}))
      end
      if es_results.response['aggregations'].present?
        return_value[:aggs] = {}
        return_value[:aggs][:regions] = es_results.response['aggregations']['regions']['buckets'].map{ |item| {id: item['key'], name: item['region_names']['buckets'].first['key'], found: item['doc_count']}}.sort_by{ |item| item[:name]}  if es_results.response['aggregations']['regions']['buckets'].size > 0
        return_value[:aggs][:states] = es_results.response['aggregations']['states']['buckets'].map{ |item| {state_code: item['key'], name: item['state_names']['buckets'].first['key'], found: item['doc_count']}}.sort_by{ |item| item[:name]}  if es_results.response['aggregations']['states']['buckets'].size > 0
      end
      return_value[:total] = es_results.results.total
      
      if !Rails.env.production?
        return_value[:search_string] = es_results.search.definition[:body] 
        return_value[:raw] = es_results 
      end
      
      return return_value
    end
  end
end