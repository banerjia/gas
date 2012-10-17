class CreateProducts < ActiveRecord::Migration
  def change
    create_table :products, :id => false do |t|
      t.string :name, :limit => 250, :null => false
      t.string :code, :limit => 10, :null => false
      t.boolean :active, :null => false, :default => true
      t.timestamps
    end
    
    execute <<-SQL
	alter table `products` change `active` `active` tinyint(1) unsigned not null default 1
    SQL

    add_index :products, :code, :unique => true
    add_index :products, [:active, :code]
  end

  def down
    drop_table :products
  end
end
