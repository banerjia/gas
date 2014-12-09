class StoreIdentifierDigest < ActiveRecord::Migration
  def up 
    add_column :stores, :active, :bool, :null => false, :default => true, :after => :longitude
    add_column :stores, :url_id, :string, :size => 256, :after => :id
    
    execute <<-SQL
      ALTER TABLE `stores`
      MODIFY `active` tinyint unsigned not null default 1
    SQL
    
    add_index :stores, :active
    add_index :stores, :url_id, :unique => true
    add_index :stores, [:active, :url_id]
    
  end
  def down
    remove_column :stores, :active
    remove_column :stores, :url_id
  end
end
