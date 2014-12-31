class AuditMetricsNeedsResolution < ActiveRecord::Migration
  def change
  	add_column :audit_metrics, :needs_resolution, :boolean, null: false, default: false, after: :score

  	add_index :audit_metrics, [:audit_id, :needs_resolution]
  end
end
