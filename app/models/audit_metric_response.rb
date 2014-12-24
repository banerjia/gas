class AuditMetricResponse < ActiveRecord::Base
  
  belongs_to :audit_metric
  belongs_to :metric_option
end