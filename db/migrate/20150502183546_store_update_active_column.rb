class StoreUpdateActiveColumn < ActiveRecord::Migration
  def change
  	reversible do |dir|
  		dir.up do
  			change_column :stores, :active, :boolean, nil: false, default: true
  		end
  		dir.down do
  			change_column :stores, :active, :integer, nil: false, default: 1

  			execute <<-SQL
				ALTER TABLE `stores` 
					MODIFY COLUMN `active` tinyint unsigned NOT NULL DEFAULT 1
  			SQL
  		end
  	end
  end
end
