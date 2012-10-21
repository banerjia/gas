class AddProductCategory < ActiveRecord::Migration
  def up
	add_column :products, :category, :string, :limit => 50, :default => 'ICE CREAM', :after => :code
	add_index :products, [:active, :category]
  end

  def down
	remove_index :products, [:active, :category]
	remove_column :products, :category
  end
end
