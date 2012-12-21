class ProductCategoryDisplayOrder < ActiveRecord::Migration
  def up
    add_column :product_categories, :display_order, :integer, :null => false, :default => 65535
    
    execute <<-SQL
      ALTER TABLE `product_categories`
        MODIFY `display_order` smallint unsigned not null default 65535
    SQL
  end

  def down
    remove_column :product_categories, :display_order
  end
end
