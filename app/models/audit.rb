class Audit < ActiveRecord::Base
	include AuditSearchable
	include AuditImport

	Audit.__elasticsearch__.client = Elasticsearch::Client.new host:  ENV["es_host"]

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
	validates_presence_of :auditor_name, message: "Please enter the name of the Graeter's staff member filling out the audit"
	validates_presence_of :created_at, message: "Please select a valid date for this audit"
	validates :store, presence: { message: "Please select a store" }
	validates :comments, presence: {message: "Audits with scores of 7 and below require comments"}, unless: Proc.new { |audit| audit.total_score > 7 }

	# Callbacks

	before_save do
		# Make sure that if is_union = false then merc_product is also false as well
		# self[:merc_product] = self[:is_union] && self[:merc_product]

		self[:auditor_name] = self[:auditor_name].strip.titlecase
		AuditMetric.where(audit_id: self[:id]).destroy_all
		Comment.delete_all({commentable_id: self[:id], commentable_type: 'Audit'})
		Image.delete_all({imageable_id: self[:id], imageable_type: 'Audit'})
	end

	after_commit do
		store.__elasticsearch__.index_document
	end

	before_destroy do |a|
		AuditMetricResponse.delete_all({audit_id: a[:id]})
	end

	# Post Rails 4 Upgrade Methods

	def total_score
		self[:base] + self[:loss] + self[:bonus]
	end

	# ElasticSearch Indexing Support Functions

	def score
		{ base: self[:base], loss: self[:loss], bonus: self[:bonus], total: self.total_score}
	end

	def as_indexed_json(options={})
		self.as_json({
			only: [:id, :auditor_name, :created_at, :has_unresolved_issues],
			methods: [:score],
			include: {
				store: {
					only: [:id],
					methods: [:full_name],
				},
				images: {
					only: [:content_url, :thumbnail_url],
					methods:[:content_url_size]
				},
				comments: {
					only: [:content]
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
