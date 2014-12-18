class AuditMetricResponses < ActiveRecord::Migration
  def up
    create_table :audit_metric_responses, id: false do |t|
      t.integer :audit_id, nil: false
      t.integer :metric_id, nil: false
      t.integer :metric_option_id, nil:false
      t.string :value, size: 1024
    end
    
    execute <<-SQL
      ALTER TABLE `audit_metric_responses`
        MODIFY COLUMN `audit_id` bigint unsigned not null,
        MODIFY COLUMN `metric_id` mediumint unsigned not null,
        MODIFY COLUMN `metric_option_id` mediumint unsigned not null
    SQL
  end
  
  def down
    drop_table :audit_metric_responses
  end
end
