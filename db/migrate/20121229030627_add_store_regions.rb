class AddStoreRegions < ActiveRecord::Migration
  def up
    create_table :regions do |t|
      t.string :name, :limit => 50, :null => false
      t.integer :company_id, :null => false
      t.integer :stores_count, :default => 0
    end
    
    execute <<-SQL
      ALTER TABLE `regions`
        MODIFY `id` mediumint unsigned not null auto_increment,
        MODIFY `company_id` mediumint unsigned not null,
        MODIFY `stores_count` smallint unsigned not null default 0
    SQL
    
    add_index :regions, [:company_id, :stores_count]
    
    add_column :stores, :region_id, :integer, :after => :company_id

    execute <<-SQL
      ALTER TABLE `stores`
        MODIFY `region_id` mediumint unsigned
    SQL
    
    add_column :companies, :regions_count, :integer, :null => false, :default => 0, :after => :stores_count
    
    execute <<-SQL
      ALTER TABLE `companies`
        MODIFY `regions_count` smallint unsigned not null default 0
    SQL
  end

  def down
    
    remove_column :companies, :regions_count
    remove_column :stores, :region_id
    
    drop_table :regions
    
  end
end
