class AuditMetric < ActiveRecord::Base
	self.primary_keys = [:audit_id, :metric_id]

	belongs_to :audit
	has_one :metric
  has_many :audit_metric_responses
end
