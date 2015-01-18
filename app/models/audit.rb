class Audit < ActiveRecord::Base
  include AuditSearchable
  include AuditImport
	
  # Associations
	belongs_to :store, counter_cache: true
	
	has_many :audit_metrics, dependent: :delete_all
  has_many :images, as: :imageable, dependent: :nullify
  has_many :comments, as: :commentable, dependent: :delete_all
  
  
  belongs_to :person	
	
	accepts_nested_attributes_for :audit_metrics, allow_destroy: true #, reject_if: Proc.new { |sm| sm[:score].blank? }
  accepts_nested_attributes_for :comments, allow_destroy: true, reject_if: Proc.new { |c| c[:content].blank? }
                                
                                
  accepts_nested_attributes_for :store, allow_destroy: false, reject_if: Proc.new { |s| s[:id].empty?}

  # Validations
  validates :store, presence: true
  validates :comments, presence: true, unless: Proc.new { |audit| audit.total_score > 9 }
	# validates_presence_of :audit_comment, unless: proc{ |audit| audit.total_score > 9 }
  
  # Callbacks
  after_validation :clear_previous_audit, on: :update

  after_commit do
    store.__elasticsearch__.index_document
  end

  before_destroy do |a|
    AuditMetricResponse.delete_all({audit_id: a[:id]})
  end


  # Methods referenced from callbacks
  def clear_previous_audit
    AuditMetric.where(audit_id: self[:id]).destroy_all
    Comment.delete_all({commentable_id: self[:id], commentable_type: 'Audit'})
  end

  # Getter and Setter methods
  def audit_comment
    (comments.order({created_at: :desc}).first || comments.build() )[:content] 
  end

  def audit_comment=(value)
    comments.build({content: value}) unless value.nil? || value.empty? 
  end

  def image_upload
    images.first[:content_url] if images.present?
  end

  def image_upload=(value)
    images.build({content_url: value}) unless value.nil? || value.empty?
  end
  
  # Post Rails 4 Upgrade Methods
  
  def total_score
    self[:base] + self[:loss] + self[:bonus]
  end

  def score
    { base: self[:base], loss: self[:loss], bonus: self[:bonus], total: self.total_score}
  end

  # ElasticSearch Indexing Support Functions

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
    # Audit.__elasticsearch__.client.indices.delete index: Audit.index_name rescue nil
    Audit.__elasticsearch__.client.indices.create index: Audit.index_name, body: { settings: Audit.settings.to_hash, mappings: Audit.mappings.to_hash}
    Audit.import
  end
end
