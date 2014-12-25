class Metric < ActiveRecord::Base
  
	has_many :metric_options
  has_many :audit_metrics
  has_many :audit_metric_responses
  
  has_and_belongs_to_many :audits, join_table: :audits
    
  # Scopes
  scope :active_metrics, ->() { where(["(start_date IS NULL OR start_date <= ?) AND (end_date IS NULL OR end_date >= ?)", Date.today, Date.today]) }
  
end
