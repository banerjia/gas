class AuditResponseReferenceUpdate < ActiveRecord::Migration
  def change
    remove_reference :audit_metric_responses, :audit_metric
    add_reference :audit_metric_responses, :audit, after: :metric_option_id
    add_reference :audit_metric_responses, :metric, after: :metric_option_id
  end
end
