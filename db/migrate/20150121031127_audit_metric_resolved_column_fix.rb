class AuditMetricResolvedColumnFix < ActiveRecord::Migration
  def change
  	reversible do |dir|
  		dir.up do
  			change_column :audit_metrics, :resolved, :boolean, default: false, null: false
  		end

  		dir.down do
  			change_column :audit_metrics, :resolved, :integer, default: 0, null: false
  		end
  	end
  end
end
