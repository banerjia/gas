class Metric < ActiveRecord::Base
	has_many :metric_options
  
  # Scopes
  scope :active_metrics, ->() { where(["(start_date IS NULL OR start_date <= ?) AND (end_date IS NULL OR end_date >= ?)", Date.today, Date.today]) }
  
end
