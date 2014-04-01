class ProductOrder < ActiveRecord::Migration
  def up
    add_column :products, :sort_order_for_order_sheet, :integer, :null => false, :default => 0, :after => :available_till
    
    execute <<-SQL
    ALTER TABLE `products`
    MODIFY `sort_order_for_order_sheet` smallint unsigned not null default 0
    SQL
  end
  
  def down
    remove_column :products, :sort_order_for_order_sheet
  end
end
