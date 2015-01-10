class AuditMetricResponse < ActiveRecord::Base
	self.primary_keys = [:audit_id, :metric_id, :metric_option_id]
	
	belongs_to :audit_metric, foreign_key: [:audit_id, :metric_id]
	belongs_to :metric_option
	
end