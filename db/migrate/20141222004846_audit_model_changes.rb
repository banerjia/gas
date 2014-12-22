class AuditModelChanges < ActiveRecord::Migration
  def up
    add_column :audit_metrics, :bonus_points, :integer, nil: false, default: 0, after: :point_value
    
    execute <<-SQL
     ALTER TABLE `audit_metrics`
     MODIFY COLUMN `bonus_points` smallint unsigned not null default 0,
     CHANGE COLUMN `point_value` `points` smallint not null default 0
    SQL
    
    [:allows_free_form, :trigger_alert, :response_type, :points_awarded, :points_deducted].each do |col|
     remove_column :metrics, col
    end
    
    add_column :metrics, :points, :integer, nil: false, default: 0, after: :include
    add_column :metrics, :apply_points_per_item, :boolean, nil: false, default: false, after: :points
    add_column :metrics, :template, :string, size: 100, after: :apply_points_per_item
     
    execute <<-SQL
      ALTER TABLE `metrics`
      MODIFY COLUMN `points` smallint not null default 0,
      MODIFY COLUMN `apply_points_per_item` tinyint unsigned not null default 0,
      MODIFY COLUMN `template` varchar(100)
    SQL
    
  end
  
  def down
    
    remove_column :audit_metrics, :bonus_points
    execute <<-SQL
      ALTER TABLE `audit_metrics`
      CHANGE COLUMN `points` `point_value` smallint default 0
    SQL
    
    
    [:points, :apply_points_per_item, :template].each do |col|
       remove_column :metrics, col
     end
    
     [:trigger_alert, :allows_free_form].each { |col| add_column :metrics, col, :boolean, nil: false, default: false, after: :display_order }
    
     [:points_awarded, :points_deducted].reverse.each do |col|
       add_column :metrics, col, :integer, nil: false, default: 0, after: :include
     end
    
     add_column :metrics, :response_type, :string, size: 100, after: :include
    
     execute <<-SQL
       ALTER TABLE `metrics`
       MODIFY COLUMN `trigger_alert` tinyint unsigned not null default 0,
       MODIFY COLUMN `allows_free_form` tinyint unsigned not null default 0,
       MODIFY COLUMN `points_awarded` smallint unsigned not null default 0,
       MODIFY COLUMN `points_deducted` smallint unsigned not null default 0
     SQL
  end
end
