module AuditSearchable
  extend ActiveSupport::Concern

  included do
    include Elasticsearch::Model
    include Elasticsearch::Model::Callbacks

    settings do
		  index_name    "graeters-#{Rails.env}-audits"
			mapping do 
				indexes :id, type: 'integer', index: 'not_analyzed'
        
        indexes :store do
          indexes :id, type: 'integer', index: 'not_analyzed'
          indexes :full_name, type: 'multi_field' do
            indexes :full_name
            indexes :raw, index: 'not_analyzed'
          end
        
          indexes :company do 
            indexes :id, type: 'integer', index: 'not_analyzed'
            indexes :name, type: 'multi_field' do
              indexes :name
              indexes :raw, index: 'not_analyzed'
            end
          end
        end
        
        indexes :person do
          indexes :id, type: 'integer', index: 'not_analyzed'
          indexes :name, type: 'multi_field' do
            indexes :name
            indexes :raw, index: 'not_analyzed'
          end
        end
        indexes :score do 
          indexes :base, type: 'integer', index: 'not_analyzed'
          indexes :loss, type: 'integer', index: 'not_analyzed'
          indexes :bonus, type: 'integer', index: 'not_analyzed'
          indexes :total, type: 'integer', index: 'not_analyzed'
        end
        indexes :created_at, type: 'date', index: 'not_analyzed'
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
        
      sort = [{ created_at: { order: "desc"}}]
      page = params[:page]      
      size = params[:per_page]
      offset = (page - 1) * size
      
      query_bool_must_array = []
      query_string = {match_all:{}}
    
      query_string = { query_string: {query: params[:q]}} if params[:q].present?
      
      query_bool_must_array.push( {term: { "store.company.id" => params[:company_id]}}) if params[:company_id].present?
      query_bool_must_array.push( {term: { "store.id" =>  params[:store_id]}}) if params[:company_id].present?
      query_bool_must_array.push( query_string )
    
      es_results = __elasticsearch__.search size: size, from: offset, 
      query: {
        bool: {
          must:query_bool_must_array
        }
      },
      filter: {
        range: {
          "score.total" => {
            gte: params[:score_lower],
            lte: params[:score_upper]
          }
        }
      },
      sort: sort,
      aggs:[
        {
          score_ranges:{
            range:{
              field: "score.total",
              ranges:[
                {to: 50},
                {from: 10, to: 19},
                {from: 0, to: 9}              
              ]
            }
          }  
        },
        {
          companies: {
            terms: {
              field: "store.company.id"
            },
            aggs: {
              company_names: {
                terms: {
                  field: "store.company.name.raw"
                }
              }
            }
          }
        }
        ]    
      
      
      return_value[:more_pages] = ((es_results.results.total.to_f / size.to_f) > page.to_f )
      return_value[:results] = es_results.results.map { |item| item._source }
      
#      if es_results.response['aggregations'].present?
#        return_value[:aggs] = {}
#        return_value[:aggs][:companies] = es_results.response['aggregations']['companies']['buckets'].map{ |item| {"company.id": item['key'], name: item['company_names']['buckets'].first['key'], found: item['doc_count']}}.sort_by{ |item| item[:name]}  if es_results.response['aggregations']['companies']['buckets'].size > 0
#      end
      
      return_value[:total] = es_results.results.total
      
      return_value[:search_string] = es_results.search.definition[:body] if !Rails.env.production?
      
      return return_value

  	end
  end
end
