class StoreMetric < ActiveRecord::Base
	self.primary_keys = [:audit_id, :metric_id]

	belongs_to :audit
	belongs_to :metric
end
