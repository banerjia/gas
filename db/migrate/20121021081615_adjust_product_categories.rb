class AdjustProductCategories < ActiveRecord::Migration
  def up
    create_table :product_categories do |t|
      t.string :name, :limit => 50, :null => false
      t.integer :volume_unit_id, :default => 1, :comment => "Default volume unit id"
      t.boolean :limited_availability, :null => false,  :default => 0
    end

    execute <<-SQL
      ALTER TABLE `product_categories`
        CHANGE COLUMN `id` `id` smallint(1) unsigned NOT NULL auto_increment
    SQL
    
    execute <<-SQL
      ALTER TABLE `product_categories`
        CHANGE COLUMN `volume_unit_id` `volume_unit_id` smallint(1) unsigned DEFAULT 1
    SQL
    
    execute <<-SQL
      ALTER TABLE `product_categories`
        CHANGE COLUMN `limited_availability` `limited_availability` tinyint(1) unsigned not null DEFAULT 0
    SQL
    
    execute <<-SQL
      INSERT `product_categories` (`name`)
        SELECT DISTINCT `category` FROM `products` WHERE `available_from` IS NULL AND `available_till` IS NULL
    SQL
    
    execute <<-SQL
      INSERT `product_categories` (`name`, `limited_availability`)
        SELECT DISTINCT `category`, 1 FROM `products` WHERE `available_from` IS NOT NULL AND `available_till` IS NOT NULL
    SQL
    
    remove_index :products, [:active, :category]  
    
    add_column :products, :product_category_id, :integer, :null => false,  :default => 1, :after => :code    
    add_index :products, [:active, :product_category_id]
    
    execute <<-SQL
      UPDATE `products` SET
        `product_category_id` = (SELECT `id` FROM `product_categories` WHERE `product_categories`.`name` = `category`)
    SQL
        
    remove_column :products, :category
  end

  def down
    add_column :products, :category, :string, :limit => 20, :null => false, :default => 'ICE CREAM', :after => :code
    
    execute <<-SQL
      UPDATE `products` SET
        `category` = (SELECT `name` FROM `product_categories` WHERE `product_categories`.`id` = `product_category_id`)
    SQL
        
    remove_index :products, [:active, :product_category_id]
    remove_column :products, :product_category_id
    add_index :products, [:active, :category]
    
    drop_table :product_categories    
  end
end
