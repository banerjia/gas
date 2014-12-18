class Audit < ActiveRecord::Base
	
	belongs_to :store, :counter_cache => true
	
	has_many :audit_metrics
	has_many :audit_journal
  has_one :people
	
	
	#accepts_nested_attributes_for :audit_metrics, :allow_destroy => true, \
  #                              :reject_if => proc { |sm| sm[:point_value].blank? }
                                
                                
  accepts_nested_attributes_for :store, :allow_destroy => false

	validates_presence_of :comments , :unless => proc{ |audit| audit[:score] > 9 }

	after_save do |audit|
		if audit.comments
			audit.audit_journal.where("tags like '%Audit%' and tags like '%Notes%'").first[:body] = @audit_comments 
			audit.save
		else
			audit.audit_journal.create( {:title => 'Audit Notes', :tags => 'Audit,Notes', :body => @audit_comments} )
		end		
	end
	
	def self.search_audits( params )
		return_value = Hash.new
		params[:score_upper] = 50 \
						if params[:score_lower].present? && params[:score_upper].present? && params[:score_lower].to_i > params[:score_upper].to_i
              
    
		tire_results = tire.search :load => {:include => [:store]}, :per_page => params[:per_page], :page => params[:page] do 
			query do
      	boolean do
      		must { string params[:q] || all} 
      		must { term :company_id, params[:company_id] }  if params[:company_id].present?
      		must { term :auditor_facet, params[:auditor] }  if params[:auditor].present?
      		must { term :store_id, params[:store] }         if params[:store].present?
      		must { range :score, from: params[:score_lower], to: params[:score_upper]} if params[:score_lower].present?
      	end
			end

			facet('chains') {terms :company_id }
			facet('auditors') {terms :auditor_facet }
			facet('scores') do 
      	range :score, [
      		{ from: 0, to: 19},
      		{ from: 20, to: 22}, 
      		{ from: 23, to: 24},
      		{ from: 25 }
      	]
			end

			sort	{by :created_at, 'desc' } 
		end

		if tire_results.count > 0 
			return_value[:audits] = tire_results.results
			facets = Hash.new

			# Organizing Company Facet
			if (params[:company_id].present? || tire_results.facets['chains']['terms'].count > 0)
      	facets['chains'] = []
      	tire_results.facets['chains']['terms'].each_with_index do |chain,index|
      		chain[:company_name] = Company.find(:first, :conditions => {:id => chain['term'].to_i}, :select => :name)[:name]
      		facets['chains'].push(chain)
      	end
      	facets['chains'].sort!{ |a,b| a[:company_name].sub(/^(the|a|an)\s+/i, '') <=> b[:company_name].sub(/^(the|a|an)\s+/i, '')}
			end

			# Organizing Auditor Facet
			if params[:auditor].present? || tire_results.facets['auditors']['terms'].count > 0
      	facets['auditors'] = []
      	tire_results.facets['auditors']['terms'].each_with_index do |auditor,index|
      		facets['auditors'].push(auditor)
      	end
      	facets['auditors'].sort!{ |a,b| a['term'] <=> b['term']}
			end

			# Organizing Scores Facet
			facets['scores'] = tire_results.facets['scores']['ranges']

			return_value[:facets] = facets
		end

		return return_value

	end
	
	def comments
		self.audit_journal.where("tags like '%Audit%' and tags like '%Notes%'").first[:body] if self.audit_journal.where("tags like '%Audit%' and tags like '%Notes%'").first
	end

	def comments=(value)	
		@audit_comments = value
	end
  
  # Post Rails 4 Upgrade Methods
  
  def total_score
    self[:base] - self[:loss] + self[:bonus]
  end
  
  def score
    { base: self[:base], loss: self[:loss], bonus: self[:bonus], total: self.total_score}
  end
end
