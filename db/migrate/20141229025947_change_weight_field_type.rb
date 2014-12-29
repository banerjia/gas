class ChangeWeightFieldType < ActiveRecord::Migration
  def change
		reversible do |dir|
			dir.up do 
				execute <<-SQL
					ALTER TABLE `metric_options`
						MODIFY COLUMN `weight` decimal(4,1) unsigned not null default 100
				SQL
			end
			dir.down do 
				execute <<-SQL
					ALTER TABLE `metric_options`
						MODIFY COLUMN `weight` smallint unsigned not null default 100
				SQL
			end
		end
  end
end
