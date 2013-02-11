class AdjustAuditColumns < ActiveRecord::Migration
  def up
	execute <<-SQL
	  	ALTER TABLE `audits`
			MODIFY `id` bigint unsigned not null auto_increment,
			MODIFY `store_id` bigint unsigned not null,
			MODIFY `points_available` smallint unsigned not null default 25,
			MODIFY `score` smallint unsigned not null default 0,
			MODIFY `status` tinyint unsigned not null default 0
	SQL
	execute <<-SQL
		ALTER TABLE `audit_journals`
			MODIFY `audit_id` bigint unsigned not null
	SQL
	
  end

  def down
  end
end
