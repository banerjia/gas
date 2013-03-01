class AddAuditsCountToStores < ActiveRecord::Migration
  def up
	add_column :stores, :audits_count, :integer, :null => false, :default => 0, :after => :orders_count
	
	execute <<-SQL
		ALTER TABLE `stores`
			MODIFY `audits_count` smallint unsigned not null default 0 
	SQL
	
	execute <<-SQL
		UPDATE `stores`
			SET `audits_count` = (SELECT COUNT(`id`) FROM `audits` WHERE `store_id` = `stores`.`id`)
	SQL
  end
  
  def down
	remove_column :stores, :audits_count
  end
end
