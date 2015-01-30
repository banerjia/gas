class Audit < ActiveRecord::Base
  include AuditSearchable
  include AuditImport
	
  # Associations
	belongs_to :store, counter_cache: true
	
	has_many :audit_metrics, dependent: :delete_all
  has_many :images, as: :imageable, dependent: :delete_all
  has_many :comments, as: :commentable, dependent: :delete_all

	
	accepts_nested_attributes_for :audit_metrics, allow_destroy: true #, reject_if: Proc.new { |sm| sm[:score].blank? }
  accepts_nested_attributes_for :comments, allow_destroy: true, reject_if: Proc.new { |c| c[:content].blank? }
  accepts_nested_attributes_for :images, allow_destroy: true, reject_if: Proc.new { |i| i[:content_url].blank? }
                                
                                
  accepts_nested_attributes_for :store, allow_destroy: false, reject_if: Proc.new { |s| s[:id].empty?}

  # Validations
  validates_associated :audit_metrics
  validates_presence_of :auditor_name, message: "Please provide a valid auditor name"
  validates_presence_of :created_at, message: "Please provide a valid audit date"
  validates :store, presence: true #, message: "Please select a store"
  validates :comments, presence: true, unless: Proc.new { |audit| audit.total_score > 9 } #, message: "Audits with scores below 10 require comments to be provided"
  
  # Callbacks

  before_save do
    AuditMetric.where(audit_id: self[:id]).destroy_all
    Comment.delete_all({commentable_id: self[:id], commentable_type: 'Audit'})
    Image.delete_all({imageable_id: self[:id], imageable_type: 'Audit'})
  end

  after_commit do
    store.__elasticsearch__.index_document
    __elasticsearch__.update_document
  end

  before_destroy do |a|
    AuditMetricResponse.delete_all({audit_id: a[:id]})
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
      only: [:id, :auditor_name, :created_at, :has_unresolved_issues],
      methods: [:score],
      include: {
        store: { 
          only: [:id, :state_code],
          methods: [:full_name, :address],
          include: {
            state: {
              only: [:state_name]
            }            
          }
        }
      }
    })
  end
  
  def self.index_refresh
    Audit.__elasticsearch__.client.indices.delete index: Audit.index_name rescue nil
    Audit.__elasticsearch__.client.indices.create index: Audit.index_name, body: { settings: Audit.settings.to_hash, mappings: Audit.mappings.to_hash}
    Audit.import
  end
end
