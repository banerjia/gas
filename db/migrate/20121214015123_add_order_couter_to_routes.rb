class AddOrderCouterToRoutes < ActiveRecord::Migration
  def up
    add_column :routes, :stores_count, :integer, :null => false, :default => 0, :after => :name
    
    execute <<-SQL
      ALTER TABLE `routes`
        MODIFY `stores_count` smallint unsigned not null default 0
    SQL
    
    execute <<-SQL
      UPDATE `routes` SET
        `stores_count` = (SELECT COUNT(`id`) FROM `orders` where `orders`.`route_id` = `routes`.`id`)
    SQL
  end
  
  def down
    remove_column :orders, :stores_count
  end
end
