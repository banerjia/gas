class AuditMetricUpdate < ActiveRecord::Migration
  def up
    [:created_at, :updated_at].each {|item| remove_column :audit_metrics, item }
  end
  
  def down
    [:created_at, :updated_at].each {|item| add_column :audit_metrics, item, :timestamp }
  end
end
