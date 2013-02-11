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
		indexes :auditor, :type => 'string', :analyzer => 'snowball'
		indexes :score, :type => 'integer',  :index => 'not_analyzed'
		indexes :status, :type => 'boolean', :index => 'not_analyzed'
		indexes :created_at, :type => 'datetime', :index => 'not_analyzed'
	end
  end
  
  def self.search_audits( params )
	results = tire.search :load => {:include => ['store']}, :per_page => params[:per_page], :page => params[:page] do 
		query do
			boolean do
			  must { string params[:q]} if params[:q].present?
			  must { string "company_id:#{params[:company_id]}" } if params[:company_id].present?
			  must { string "auditor:#{params[:auditor]}" } if params[:auditor].present?
			  must { string "store_id:#{params[:store]}" } if params[:store].present?
			end
      		end

		facet('chain') { :company_id }
      
      		sort  {by :created_at, 'desc' } 
	end

  end
  
  def is_pending?
	  self[:status] == 0
  end
end
