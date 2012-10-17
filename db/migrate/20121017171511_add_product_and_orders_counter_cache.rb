class AddProductAndOrdersCounterCache < ActiveRecord::Migration
  def up
	change_table :stores do |t|
		t.integer :orders_count, :null => false, :default => 0, :after => :phone
	end

	execute <<-SQL
		ALTER TABLE `stores` 
			CHANGE COLUMN `orders_count` `orders_count` mediumint(5) unsigned not null default 0
	SQL
	
	execute <<-SQL
		UPDATE `stores` SET
			`orders_count` = (SELECT COUNT(*) FROM `orders` WHERE `store_id` = `stores`.`id`)
	SQL

	change_table :orders do |t|
		t.integer :products_count, :null => false, :default => 0, :after => :store_id
	end

	execute <<-SQL
		ALTER TABLE `orders`
			CHANGE COLUMN `products_count` `products_count` mediumint(5) unsigned not null default 0
	SQL

	execute <<-SQL
		UPDATE `orders` SET
			`products_count` = (SELECT COUNT(*) FROM `product_orders` WHERE `order_id` = `id`)
	SQL
 
  end

  def down
	remove_column :stores, :orders_count
	remove_column :orders, :products_count
  end
end
