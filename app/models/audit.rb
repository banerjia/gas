class Audit < ActiveRecord::Base
  include Tire::Model::Search
  include Tire::Model::Callbacks
  
  belongs_to :store, :counter_cache => true
  
  has_many :metrics
  has_many :audit_journal
  
  tire do
  	index_name('audits')
  	mapping do
  		indexes :id,	:type=>'integer', :index => 'not_analyzed'
  		indexes :store_id, :type => 'integer', :index => 'not_analyzed'
  		indexes :company_id, :type => 'integer', :index => 'not_analyzed', :as => 'store.company_id'
  		indexes :company_name, :type => 'string', :index => 'not_analyzed', :as => 'store.company[:name]'
  		indexes :store_name, :type => 'string', :analyzer => 'snowball', :as => 'store.name_with_locality'
  		indexes :auditor_facet, :type => 'string', :index => 'not_analyzed', :as => 'auditor_name', :include_in_all => false
  		indexes :auditor_name, :type => 'string', :analyzer => 'snowball'
  		indexes :score, :type => 'integer',  :index => 'not_analyzed'
  		indexes :status, :type => 'boolean', :index => 'not_analyzed', :as => 'status == true'
  		indexes :created_at, :type => 'date', :index => 'not_analyzed'
  	end
  end
  
  def self.search_audits( params )
    return_value = Hash.new
  	tire_results = tire.search :load => {:include => ['store']}, :per_page => params[:per_page], :page => params[:page] do 
  		query do
  			boolean do
  			  must { string params[:q]} if params[:q].present?
  			  must { string "company_id:#{params[:company_id]}" } if params[:company_id].present?
  			  must { string "auditor:#{params[:auditor]}" } if params[:auditor].present?
  			  must { string "store_id:#{params[:store]}" } if params[:store].present?
  			end
      end

  		facet('chains') {terms :company_id }
  		facet('auditors') {terms :auditor_facet }
      
      sort  {by :created_at, 'desc' } 
  	end
  	
  	if tire_results.count > 0 
  	  return_value[:results] = tire_results.results
  	  facets = Hash.new
  	  
  	  if params[:company_id].present? || tire_results.facets['chains']['terms'].count > 0
        facets['chains'] = []
        tire_results.facets['chains']['terms'].each_with_index do |chain,index|
          chain[:company_name] = Company.find(chain['term'].to_i)[:name]
          facets['chains'].push(chain)
        end
        facets['chains'].sort!{ |a,b| a[:company_name].sub(/^(the|a|an)\s+/i, '') <=> b[:company_name].sub(/^(the|a|an)\s+/i, '')}
      end

  	  if params[:auditor].present? || tire_results.facets['auditors']['terms'].count > 0
        facets['auditors'] = []
        tire_results.facets['auditors']['terms'].each_with_index do |auditor,index|
          facets['auditors'].push(auditor)
        end
        facets['auditors'].sort!{ |a,b| a['term'] <=> b['term']}
      end
  	    
  	  
  	  return_value[:facets] = facets
	  end

    return return_value

  end
  
  def is_pending?
	  self[:status] == 0
  end
end
