class AuditMetric < ActiveRecord::Base
	belongs_to :audit
	belongs_to :metric
	
	has_many :audit_metric_responses, foreign_key: [:audit_id, :metric_id], primary_key: [:audit_id, :metric_id]
	
	accepts_nested_attributes_for :audit_metric_responses #, allow_destroy: true
end
