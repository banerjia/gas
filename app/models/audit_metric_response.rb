class AuditMetricResponse < ActiveRecord::Base
  
  belongs_to :audit_metric
  belongs_to :metric_option
  belongs_to :audit_metrics, foreign_key: [:audit_id, :metric_id], primary_key: [:audit_id, :metric_id, :metric_option_id]
  
end