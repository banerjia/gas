module AuditSearchable
  extend ActiveSupport::Concern

  included do
    include Elasticsearch::Model
    include Elasticsearch::Model::Callbacks

    settings do
		  index_name    "graeters-#{Rails.env}-audits"
			mapping do 
				indexes :id, type: 'integer', index: 'not_analyzed'
        indexes :store_id, type: 'integer', index: 'not_analyzed'

        indexes :store do 
          indexes :id, type: 'integer', index: 'not_analyzed'
          indexes :address, type: 'string', index: 'not_analyzed'
          indexes :state_code, type: 'string', index: 'not_analyzed'
          indexes :full_name, type: 'multi_field' do
            indexes :full_name
            indexes :raw, index: 'not_analyzed'
          end
          indexes :state do 
            indexes :state_name, type: 'string', index: 'not_analyzed'
          end
        end
        
        indexes :auditor_name, type: 'multi_field' do
          indexes :auditor_name
          indexes :raw, index: 'not_analyzed'
        end
        indexes :score do 
          indexes :base, type: 'integer', index: 'not_analyzed'
          indexes :loss, type: 'integer', index: 'not_analyzed'
          indexes :bonus, type: 'integer', index: 'not_analyzed'
          indexes :total, type: 'integer', index: 'not_analyzed'
        end
        indexes :audit_date, type: 'date', index: 'not_analyzed'
        indexes :has_unresolved_issues, type: 'boolean', index: 'not_analyzed'
      end
    end
    
  	def self.search( params )
  		return_value = Hash.new
      
      if params[:score_lower].present?
  		    params[:score_upper] = 50 if !params[:score_upper].present? || (params[:score_upper].present? && params[:score_lower].to_i > params[:score_upper].to_i)
      else 
        params[:score_lower] = 0 if !params[:score_lower].present? && params[:score_upper].present?
      end
        
      sort = []
      if params[:sort].present?
        default_order = "asc"
        params[:sort].split(',').each do |sort_spec|
          sort_spec_parts = /([^-]+)\-?(.*)/.match(sort_spec)
          sort.push({sort_spec_parts[1].to_sym => {order: (sort_spec_parts[2].blank? ? default_order : sort_spec_parts[2])}})
        end
      else
        sort.push({ created_at: { order: "desc"}})
      end
      
      page = (params[:page] || 1).to_i   
      size = (params[:per_page] || 10).to_i
      offset = (page - 1) * size
      
      query_bool_array_must = []
      query_bool_array_must.push({constant_score: {filter: { match_all:{}}}})

      query_bool_array_must.push( {term: {"store.id" => params[:store_id]}}) if params[:store_id].present?
      query_bool_array_must.push( {term: {"store.state_code" => params[:state]}}) if params[:state].present?
      query_bool_array_must.push( {term: {"store.company.id" => params[:company_id]}}) if params[:company_id].present?
      query_bool_array_must.push( {range: {created_at: {gte: params[:start_date]}}}) unless params[:start_date].nil? || params[:start_date].blank?
      query_bool_array_must.push( {range: {created_at: {lte: params[:end_date]}}}) unless params[:end_date].nil? || params[:end_date].blank?
    
      query_bool_array_must.push( { query_string: {query: params[:q]}} ) if params[:q].present?
      

      filter_bool_must_array = []
      filter_bool_must_array.push( {term: { "store.company.id" => params[:_company_id]}}) if params[:_company_id].present?
      filter_bool_must_array.push( {term: { "store.id" =>  params[:_store_id]}}) if params[:_store_id].present?
      filter_bool_must_array.push( {range: {"score.total" => {gte: params[:_score_lower], lte: params[:_score_upper]}}}) if params[:_score_lower].present?
      filter_bool_must_array.push( {term: {auditor_name: params[:_auditor]}}) unless !params[:_auditor].present? || params[:_auditor].blank?

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
    
      es_results = __elasticsearch__.search size: size, from: offset, 
      query: query_bool_array_must,
      filter: {
        bool:{
          must: filter_bool_must_array
        }
      },
      sort: sort,
      aggs:{
        score_ranges:{
          range:{
            field: "score.total",
            ranges:[
              {from: 20},
              {from: 10, to: 19},
              {from: 0, to: 9}              
            ]
          }
        },
        auditors: {
          terms:{
            field: "auditor_name.raw"
          }
        },
        states: {
          terms:{
            field: "store.state_code"
          },
          aggs:{
            state_names: {
              terms:{
                field: "store.state.state_name"
              }
            }
          }
        } 
      }
          
      
      
      return_value[:more_pages] = ((es_results.results.total.to_f / size.to_f) > page.to_f )
      return_value[:results] = es_results.results.map { |item| item._source }      
      return_value[:total] = es_results.results.total
      return_value[:sort] = sort

      return_value[:aggs] = {}

      return_value[:aggs][:score_ranges] = es_results.response['aggregations']['score_ranges']['buckets'].map{|item| {name: item['key'].gsub(/\.0/,'').gsub(/\-\*$/,'+'), found: item['doc_count'].to_i, from: item['from'], to: item['to']}}.sort_by{ |i| i[:from]}.reverse
      return_value[:aggs][:auditors] = es_results.response['aggregations']['auditors']['buckets'].map{ |item| {name: item['key'], found: item['doc_count']}}.sort_by{ |item| item[:name]}  
      return_value[:aggs][:states] = es_results.response['aggregations']['states']['buckets'].map{ |item| {state_name: item['state_names']['buckets'].first['key'], state_code: item['key'], found: item['doc_count']}}.sort_by{ |item| item[:state_name]}  


      return_value[:search_string] = es_results.search.definition[:body] if !Rails.env.production?
      return_value[:params] = params if !Rails.env.production?
      
      return return_value

  	end
  end
end
