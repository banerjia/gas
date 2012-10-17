class CreateOrders < ActiveRecord::Migration
  def change
    create_table :orders do |t|
      t.datetime :delivery_date
      t.boolean :fulfilled, :null => false, :default => false
      t.references :store
      t.timestamps
    end

    execute <<-SQL 
	alter table `orders` change `fulfilled` `fulfilled` tinyint(1) unsigned not null default 1;
    SQL
    execute <<-SQL 
	alter table `orders` change `id` `id` int(11) unsigned not null auto_increment;
    SQL

    add_index :orders, :store_id
    add_index :orders, [:fulfilled, :id]

    create_table :product_orders, :id => false do |t|
      t.references :order, :null => false
      t.string :product_code, :limit => 10, :null => false
      t.integer :quantity, :null => false, :default => 1
      t.timestamps
    end

    execute <<-SQL
	alter table `product_orders` change `quantity` `quantity` smallint(1) unsigned not null default 1;
    SQL
    execute <<-SQL
	alter table `product_orders` change `order_id` `order_id` int(11) unsigned not null; 
    SQL

    add_index :product_orders, [:order_id, :product_code], :unique => true
    add_index :product_orders, :product_code
    add_index :product_orders, :order_id
  end

  def down
    drop_table :orders
    drop_table :product_orders
  end
end
