class AuditMetric < ActiveRecord::Base
  self.primary_keys = [:audit_id, :metric_id]

  attr_accessor :comment

	belongs_to :audit
  belongs_to :metric
  
  has_many :audit_metric_responses
  
  accepts_nested_attributes_for :audit_metric_responses

end
