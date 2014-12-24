class MetricOption < ActiveRecord::Base
  belongs_to :metric
  
  has_many :audit_metric_responses
end