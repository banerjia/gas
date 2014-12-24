class MetricAndAuditUpdates < ActiveRecord::Migration
  def up
    ## METRICS
    
    [:allows_free_form, :trigger_alert, :points_awarded, :points_deducted].each do |col|
      remove_column :metrics, col
    end
    
    add_column :metrics, :group_score_with, :integer, after: :display_order
    add_column :metrics, :apply_points_per_item, :boolean, nil: false, default: false, after: :include
    add_column :metrics, :scoring_formula, :string, length: 255, after: :apply_points_per_item
    add_column :metrics, :free_form_response, :boolean, nil: false, default: false, after: :include
     
    execute <<-SQL
      ALTER TABLE `metrics`
      MODIFY COLUMN `group_score_with` mediumint unsigned,
      MODIFY COLUMN `apply_points_per_item` tinyint unsigned not null default 0,
      MODIFY COLUMN `free_form_response` tinyint unsigned not null default 0
    SQL
    
    ## METRIC OPTIONS
    
    create_table :metric_options do |t|
      t.references :metric
      t.string :label, length: 30
      t.string :expected_value_type, length: 20, nil: false, default: 'integer'
      t.integer :base_score_value, nil: false, default: 0
      t.integer :loss_score_value, nil: false, default: 0
      t.integer :bonus_score_value, nil: false, default: 0
      t.integer :display_order, nil: false, default: 0
      t.integer :weight, nil: false, default: 100
    end
    
    execute <<-SQL
      ALTER TABLE `metric_options`
        MODIFY COLUMN `id` mediumint unsigned not null auto_increment,
        MODIFY COLUMN `metric_id` mediumint unsigned not null,
        MODIFY COLUMN `display_order` smallint unsigned not null default 0,
        MODIFY COLUMN `base_score_value` smallint unsigned not null default 0,
        MODIFY COLUMN `loss_score_value` smallint unsigned not null default 0,
        MODIFY COLUMN `bonus_score_value` smallint unsigned not null default 0,
        MODIFY COLUMN `weight` smallint unsigned not null default 100
    SQL
    
    ## AUDITS
    [:points_available, :status, :score, :auditor_name, :store_rep].each { |item| remove_column :audits, item}
    
    add_column :audits, :person_id, :int, nil: false, after: :store_id
    add_column :audits, :base, :int, nil: false, default: 0, after: :person_id
    add_column :audits, :loss, :int, nil: false, default: 0, after: :base
    add_column :audits, :bonus, :int, nil: false, default: 0, after: :loss
    add_column :audits, :has_unresolved_issues, :boolean, nil: false, default: false, after: :bonus
    
    execute <<-SQL
      ALTER TABLE `audits`
        MODIFY COLUMN `person_id` mediumint unsigned not null,
        MODIFY COLUMN `base` smallint unsigned not null default 0,
        MODIFY COLUMN `loss` smallint unsigned not null default 0,
        MODIFY COLUMN `bonus` smallint unsigned not null default 0,
        MODIFY COLUMN `has_unresolved_issues` tinyint unsigned not null default 0
    SQL
    
    add_index :audits, [:store_id, :has_unresolved_issues]
    add_index :audits, [:store_id, :person_id]
    
    ## AUDIT METRICS
    create_table :audit_metrics, id: false do |t|
      t.references :audit
      t.references :metric
      t.integer :bonus, nil: false, default: 0
      t.integer :loss, nil: false, default: 0
      t.integer :base, nil: false, default: 0
    end
    
    execute <<-SQL
     ALTER TABLE `audit_metrics`
     MODIFY COLUMN `audit_id` bigint unsigned not null, 
     MODIFY COLUMN `metric_id` mediumint unsigned not null, 
     MODIFY COLUMN `bonus` smallint unsigned not null default 0,
     MODIFY COLUMN `base` smallint not null default 0,
     MODIFY COLUMN `loss` smallint not null default 0
    SQL
    
    ## AUDIT METRIC RESPONSES
    create_table :audit_metric_responses, id: false do |t|
      t.references :audit_metric
      t.references :metric_option
      t.boolean :selected, nil: false, default: true
      t.string :entry_value, size: 255
    end
    
    execute <<-SQL
      ALTER TABLE `audit_metric_responses`
        MODIFY COLUMN `audit_metric_id` bigint unsigned not null,
        MODIFY COLUMN `metric_option_id` mediumint unsigned not null,
        MODIFY COLUMN `selected` tinyint unsigned not null default 1,
        MODIFY COLUMN `entry_value` smallint unsigned not null default 0
    SQL
    
    ## IMAGES
  	create_table :images, id: false do |t|
  		t.references :imageable, polymorphic: true, index: true
  		t.string :image_type, nil: false, default: 'jpeg', size: 20
  		t.string :file, nil: false, size: 255

  		t.timestamps
  	end

  	execute <<-SQL
    	ALTER TABLE `images`
    	MODIFY COLUMN `imageable_id` bigint unsigned not null
  	SQL
    
    ## PEOPLE  
    
    execute <<-SQL
      ALTER TABLE `people`
        MODIFY COLUMN `id` mediumint unsigned not null AUTO_INCREMENT
    SQL
  end
  
  #########################################
  ##
  ## REVERSING THE MIGRATION
  ##
  #########################################
  
  
  def down
    
    ## METRICS
    
    [:allows_free_form, :trigger_alert].each do |col|
      add_column :metrics, col, :boolean, nil: false, default: false, after: :display_order
    end
    
    [:points_awarded, :points_deducted].each do |col|
      add_column :metrics, col, :integer, nil: false, default: 0, after: :response_type
    end
    
    [:group_score_with,:apply_points_per_item,:scoring_formula,:free_form_response].each do |col|
      remove_column :metrics, col
    end
    
    execute <<-SQL
      ALTER TABLE `metrics`
        MODIFY COLUMN `allows_free_form` tinyint unsigned not null default 0,
        MODIFY COLUMN `trigger_alert` tinyint unsigned not null default 0,
        MODIFY COLUMN `points_awarded` smallint unsigned not null default 0,
        MODIFY COLUMN `points_deducted` smallint unsigned not null default 0
    SQL
    
    ## METRIC OPTIONS
    drop_table :metric_options
    
    ## AUDITS
    remove_index :audits, [:store_id, :has_unresolved_issues]
    remove_index :audits, [:store_id, :person_id]
    
    [:person_id, :base, :loss, :bonus, :has_unresolved_issues].each { |item| remove_column :audits, item}
    
    [:score, :points_available].each { |item| add_column :audits, item, :int, default: 0, nil: false, after: :store_id}
    [:store_rep, :auditor_name].each { |item| add_column :audits, item, :string, length: 100, after: :score}
    
    add_column :audits, :status, :boolean, nil: false, default: 1, after: :score
    
    execute <<-SQL
      ALTER TABLE `audits`
        MODIFY COLUMN `score` smallint unsigned not null default 0,
        MODIFY COLUMN `points_available` smallint unsigned not null default 0,
        MODIFY COLUMN `status` tinyint unsigned not null default 0
    SQL
    
    ## AUDIT METRICS
    drop_table :audit_metrics
    
    ## AUDIT METRIC RESPONSES    
    drop_table :audit_metric_responses
    
    ## IMAGES
    drop_table :images    
    
    ## PEOPLE

    execute <<-SQL
      ALTER TABLE `people`
        MODIFY COLUMN `id` int not null AUTO_INCREMENT
    SQL
    
  end
end
