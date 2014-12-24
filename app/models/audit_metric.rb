class AuditMetric < ActiveRecord::Base
	self.primary_keys = [:audit_id, :metric_id]

  attr_accessor :comment

	belongs_to :audit
  
  has_many :audit_metric_responses
end
