class AuditsUpdate < ActiveRecord::Migration
  def up
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
    
    
  end
  
  def down
    [:person_id, :base, :loss, :bonus, :has_unresolved_issues].each { |item| remove_column :audits, item}
    
    [:score, :points_available].each { |item| add_column :audits, item, :int, default: 0, nil: false, after: :store_id}
    [:store_rep, :auditor_name].each { |item| add_column :audits, item, :string, after: :score}
    
    add_column :audits, :status, :boolean, nil: false, default: 1, after: :score
    
    execute <<-SQL
      ALTER TABLE `audits`
        MODIFY COLUMN `score` smallint unsigned not null default 0,
        MODIFY COLUMN `points_available` smallint unsigned not null default 0,
        MODIFY COLUMN `status` tinyint unsigned not null default 0
    SQL
  end
end
