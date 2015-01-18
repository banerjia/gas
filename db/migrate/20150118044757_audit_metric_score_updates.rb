class AuditMetricScoreUpdates < ActiveRecord::Migration
  def change

  	add_column :audit_metrics, :bonus, :integer, default: 0, null: false, after: :score_type
  	add_column :audit_metrics, :loss, :integer, default: 0, null: false, after: :score_type

  	reversible do |dir|
  		dir.up do
  			execute <<-SQL
				ALTER TABLE `audit_metrics`
					MODIFY COLUMN `bonus` smallint unsigned not null default 0,
					MODIFY COLUMN `loss` smallint not null default 0,
          CHANGE COLUMN `score` `base` smallint unsigned default 0 not null
  			SQL

  			execute <<-SQL
				ALTER TABLE `audits`
					MODIFY COLUMN `loss` smallint not null default 0
  			SQL
  		end

  		dir.down do 
        execute <<-SQL
        ALTER TABLE `audit_metrics`
          CHANGE COLUMN `base` `score` smallint unsigned default 0 not null
        SQL
  			execute <<-SQL
				ALTER TABLE `audits`
					MODIFY COLUMN `loss` smallint unsigned not null default 0
  			SQL
  		end
  	end
  end
end
