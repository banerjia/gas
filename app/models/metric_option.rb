class MetricOption < ActiveRecord::Base
  belongs_to :metric, counter_cache: true
  
  has_many :audit_metric_responses
  has_many :audit_metrics, through: :audit_metric_response
  
end