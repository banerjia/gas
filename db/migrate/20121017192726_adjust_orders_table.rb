class AdjustOrdersTable < ActiveRecord::Migration
  def up
	remove_column :orders, :products_count
	execute <<-SQL
		ALTER TABLE `orders`
			CHANGE COLUMN `fulfilled` `fulfilled` tinyint(1) unsigned not null default 0
	SQL
  end

  def down
	change_table :orders do |t|
		t.integer :products_count, :null => false, :default => 0, :after => :store_id
	end

	execute <<-SQL
		ALTER TABLE `orders`
			CHANGE COLUMN `fulfilled` `fulfilled` tinyint(1) unsigned not null default 1
	SQL
		
  end
end
