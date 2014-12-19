class Audit < ActiveRecord::Base
  include AuditSearchable
  include AuditImport
	
	belongs_to :store, :counter_cache => true
	
	has_many :audit_metrics
	has_many :audit_journal
  
  belongs_to :person
	
	
	#accepts_nested_attributes_for :audit_metrics, :allow_destroy => true, \
  #                              :reject_if => proc { |sm| sm[:point_value].blank? }
                                
                                
  accepts_nested_attributes_for :store, :allow_destroy => false

  # Commented while testing
	#validates_presence_of :comments , :unless => proc{ |audit| audit.total_score > 9 }
  
  # Callbacks
  after_commit do
    store.__elasticsearch__.index_document
  end
  
  # Post Rails 4 Upgrade Methods
  
  def total_score
    self[:base] - self[:loss] + self[:bonus]
  end
  
  def score
    { base: self[:base], loss: self[:loss], bonus: self[:bonus], total: self.total_score}
  end

  def as_indexed_json(options={})
    self.as_json({
      only: [:id, :created_at, :has_unresolved_issues],
      methods: [:score],
      include: {        
        store: { only: [:id], methods: [:full_name], include: {company: { only: [:id, :name] }}},
        person: { only: [:id, :name]}
      }
    })
  end
  
  def self.index_refresh
    Audit.__elasticsearch__.client.indices.delete index: Audit.index_name rescue nil
    Audit.__elasticsearch__.client.indices.create index: Audit.index_name, body: { settings: Audit.settings.to_hash, mappings: Audit.mappings.to_hash}
    Audit.import
  end
end
