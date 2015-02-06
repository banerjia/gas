module OrderSearchable
  extend ActiveSupport::Concern

  included do
    include Elasticsearch::Model
    include Elasticsearch::Model::Callbacks

    settings do
		  index_name    "graeters-#{Rails.env}-orders"
      mapping do 
        indexes :id, type: 'integer', index: 'not_analyzed'
        indexes :invoice_number, type: 'string', index: 'not_analyzed'
        indexes :email_sent, type: 'boolean', index: 'not_analyzed'

        indexes :store do
          indexes :id, type: 'integer', index: 'not_analyzed'
          indexes :full_name, type: 'string', index: 'not_analyzed'
          indexes :state_code, type: 'string', index: 'not_analyzed'
          indexes :state do 
            indexes :state_name, type: 'string', index: 'not_analyzed'
          end

          indexes :company do 
            indexes :id, type: 'integer', index: 'not_analyzed'
            indexes :name, type: 'string', index: 'not_analyzed'
          end
        end

        indexes :delivery_day_of_the_week, type: 'string', index: 'not_analyzed'
        indexes :created_at, type: 'date', index: 'not_analyzed'
        indexes :route do
          indexes :id, type: 'integer', index: 'not_analyzed'
          indexes :name, type: 'string', index: 'not_analyzed'
        end

      end
    end
    
  	def self.search( search_params = {})
  		return_value = Hash.new
      
      page = search_params[:page] || 1      
      size = search_params[:per_page] || 10
      offset = (page - 1) * size  

      # Including time in dates for proper search 
      start_date = end_date = nil
      start_date = search_params[:start_date].to_date.beginning_of_day.to_time if search_params[:start_date].present?    
      end_date = search_params[:end_date].to_date.end_of_day.to_time if search_params[:end_date].present?    

      # TO DO: Implement functionality to have only certain fields returned in the query set. 
      fields = {}      

      # Query
      query_bool_array_must = []

      # This is the default bool array setting for queries.
      # If no other query parameters are provided then 
      # this will push the query through. On the other 
      # hand if there are other query parameters added to the
      # array then this item is popped off the array. 
      query_bool_array_must.push({constant_score: {filter: { match_all:{}}}})

      query_bool_array_must.push( {term: {"store.company.id" => search_params[:company_id]}}) if search_params[:company_id].present?
      query_bool_array_must.push( {term: {"store.id" => search_params[:store_id]}}) if search_params[:store_id].present?
      query_bool_array_must.push( {term: {"store.state_code" => search_params[:shipping_state]}}) if search_params[:shipping_state].present?
      query_bool_array_must.push( {term: {"route.id" => search_params[:route]}}) if search_params[:route].present?
      query_bool_array_must.push( {term: {"email_sent" => search_params[:email_sent]}}) if search_params[:email_sent].present?
      query_bool_array_must.push( {range: {created_at: {gte: search_params[:start_date]}}}) unless start_date.nil?
      query_bool_array_must.push( {range: {created_at: {lte: search_params[:end_date]}}}) unless end_date.nil?
      query_bool_array_must.push( {query_string: {query: search_params[:q]}}) if search_params[:q].present? && !search_params[:q].blank?
      
      if query_bool_array_must.size > 1
        # If query_bool_array_must.size > 1 => there are other
        # query parameters provided for the query. So pop-off the
        # default match_all criteria that was added earlier on.
        query_bool_array_must.delete_at(0) if query_bool_array_must.size > 1

        # Rearranging the object to look like a BOOL query object
        
      end

      query_bool_array_must = {bool: {must: query_bool_array_must}}

      # Filter
      filter_bool_array_must = []

      filter_bool_array_must.push( {term: {"store.company.id" => search_params[:_company_id]}}) if search_params[:_company_id].present?
      filter_bool_array_must.push( {term: {"store.id" => search_params[:_store_id]}}) if search_params[:_store_id].present?
      filter_bool_array_must.push( {term: {"store.state_code" => search_params[:_shipping_state]}}) if search_params[:_shipping_state].present?
      filter_bool_array_must.push({term: {"route.id" => search_params[:_route]}}) if search_params[:_route].present?
      filter_bool_array_must.push({term: {"email_sent" => search_params[:_email_sent]}}) if search_params[:_email_sent].present?
      
      # Sort
      sort_array = [
        {created_at: {order:"desc"}}
      ]
      if search_params[:sort].present?
        sort_array = []
        search_params[:sort].split(',').each do |sort_spec|
          default_order = "asc"
          sort_spec_parts = /([^-]+)\-?(.*)/.match(sort_spec)
          sort_array.push({sort_spec_parts[1].to_sym => {order: (sort_spec_parts[2].blank? ? default_order : sort_spec_parts[2])}})
        end
      end

      es_results = __elasticsearch__.search size: size, from: offset, 
      query: query_bool_array_must,
      filter: {
        bool:{
          must: filter_bool_array_must
        }
      },
      sort: sort_array,
      aggs:{
        companies:{
          terms:{
            field: "store.company.id"
          },
          aggs:{
            company_names:{
              terms:{
                field: "store.company.name"
              }
            }
          }
        },
        states:{
          terms:{
            field: "store.state_code"
          },
          aggs:{
            state_names:{
              terms:{
                field: "store.state.state_name"
              }
            }
          }
        },
        routes:{
          terms:{
            field: "route.id"
          },
          aggs:{
            route_names:{
              terms:{
                field: "route.name"
              }
            }
          }
        }  
      }     
      
      return_value[:results] = es_results.results.map { |item| item._source }      

      return_value[:aggs] = {}
      return_value[:aggs][:states] = es_results.response['aggregations']['states']['buckets'].map{ |item| {state_code: item['key'], name: item['state_names']['buckets'].first['key'], found: item['doc_count']}}.sort_by{ |item| item[:name]}  if es_results.response['aggregations']['states']['buckets'].size > 0      
      return_value[:aggs][:companies] = es_results.response['aggregations']['companies']['buckets'].map{ |item| {id: item['key'], name: item['company_names']['buckets'].first['key'], found: item['doc_count']}}.sort_by{ |item| item[:name]}  if es_results.response['aggregations']['companies']['buckets'].size > 0      
      return_value[:aggs][:routes] = es_results.response['aggregations']['routes']['buckets'].map{ |item| {id: item['key'], name: item['route_names']['buckets'].first['key'], found: item['doc_count']}}.sort_by{ |item| item[:name]}  if es_results.response['aggregations']['routes']['buckets'].size > 0      
      
      return_value[:total] = es_results.results.total
      return_value[:dates] = [search_params[:start_date], search_params[:end_date]]
      return_value[:sort] = sort_array

      return_value[:search_string] = es_results.search.definition[:body] if !Rails.env.production?

      return return_value

  	end
  end
end
