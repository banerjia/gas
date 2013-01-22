class CorrectStoreFieldTypes < ActiveRecord::Migration
  def up
	execute <<-SQL
		ALTER TABLE `stores` MODIFY id bigint unsigned not null auto_increment
	SQL
	
	execute <<-SQL
		ALTER TABLE `stores` MODIFY company_id mediumint unsigned not null
	SQL
  end

  def down
  end
end
