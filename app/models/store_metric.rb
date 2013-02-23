class StoreMetric < ActiveRecord::Base
	belongs_to :audit
	belongs_to :metric
end
