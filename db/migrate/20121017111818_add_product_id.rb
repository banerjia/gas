class AddProductId < ActiveRecord::Migration
  def up
	remove_index :products, :code
	remove_index :product_orders, [:order_id, :product_code]	
	remove_index :product_orders, :product_code
	execute <<-SQL
		ALTER TABLE `products`
			ADD COLUMN `id` int(11) unsigned not null auto_increment first, add primary key (`id`)
	SQL
        execute <<-SQL
		ALTER TABLE `product_orders`
			DROP COLUMN `product_code`,
			ADD COLUMN `product_id` int(11) unsigned not null after `order_id`
	SQL
	
	add_index :product_orders, [:order_id, :product_id],:unique => true
	add_index :product_orders, [:product_id]
  end

  def down
	remove_index :product_orders, [:order_id,:product_id]
	remove_index :product_orders, :product_id

	# Preserve any associations before the field change
	execute <<-SQL
		ALTER TABLE `product_orders` 
			ADD COLUMN `product_code` varchar(10) after `order_id`
	SQL

	execute <<-SQL
		UPDATE `product_orders` SET
			`product_code` = (SELECT `product_code` FROM `products` WHERE `id` = `product_id`)
	SQL
	
	# Drop the necessary columns
	execute <<-SQL
		ALTER TABLE `products` DROP COLUMN `id`
	SQL

	execute <<-SQL
		ALTER TABLE `product_orders` DROP COLUMN `product_id`
	SQL

	#Re-index PRODUCT_ORDERS table
	add_index :product_orders, [:order_id,:product_code], :unique => true
	add_index :product_orders, :product_code
	add_index :products, :code, :unique => true
  end
end
