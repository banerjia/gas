class MetricsUpdate < ActiveRecord::Migration
  def up
    [:points, :quantifier, :category, :reverse_options].each { |item| remove_column :metrics, item }  
    
    add_column :metrics, :response_type, :string, size: 30, nil: false, default: 'radio', after: :include
    add_column :metrics, :points_awarded, :int, nil: false, default: 0, after: :response_type
    add_column :metrics, :points_deducted, :int, nil: false, default: 0, after: :points_awarded
    

    execute <<-SQL
      ALTER TABLE `metrics`
        MODIFY COLUMN `id` mediumint unsigned not null auto_increment,
        MODIFY COLUMN `points_awarded` smallint unsigned not null default 0,
        MODIFY COLUMN `points_deducted` smallint unsigned not null default 0
    SQL
    
    create_table :metric_options do |t|
      t.integer :metric_id, nil: false
      t.string :label, size: 30, nil: false
      t.integer :value, nil:false, default: 0
      t.integer :display_order, nil: false, default: 0
      t.integer :weight, nil: false, default: 100
    end
    
    execute <<-SQL
      ALTER TABLE `metric_options`
        MODIFY COLUMN `id` mediumint unsigned not null auto_increment,
        MODIFY COLUMN `metric_id` mediumint unsigned not null,
        MODIFY COLUMN `value` smallint unsigned not null default 0,
        MODIFY COLUMN `display_order` smallint unsigned not null default 0,
        MODIFY COLUMN `weight` smallint unsigned not null default 100
    SQL
  end
  
  def down
    drop_table :metric_options
    [:points_awarded, :points_deducted, :is_bonus].each { |item| remove_column :metrics, item }
    [:points, :quantifier].each { |item| add_column :metrics, item, :int}
    
    add_column :metrics, :category, :string    
    add_column :metrics, :reverse_options, :boolean
  end
end
