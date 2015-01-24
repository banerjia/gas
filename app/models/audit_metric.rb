class AuditMetric < ActiveRecord::Base
	self.primary_keys = [:audit_id, :metric_id]

	belongs_to :audit
	belongs_to :metric
	
	has_many :audit_metric_responses, foreign_key: [:audit_id, :metric_id], dependent: :delete_all

	has_many :metric_options, through: :audit_metric_responses
	
	accepts_nested_attributes_for :audit_metric_responses, reject_if: Proc.new { |a_m_r| a_m_r[:metric_option_id].to_i.zero? }

	validates_associated :audit_metric_responses
end
