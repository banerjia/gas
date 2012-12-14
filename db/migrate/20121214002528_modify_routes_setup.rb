class ModifyRoutesSetup < ActiveRecord::Migration
  def up
    # Create routes table
    
    create_table :routes do |t|
      t.string :name, :limit => 50, :null => false
      t.boolean :active, :null => false, :default => true
    end
    
    execute <<-SQL
      ALTER TABLE `routes`
        MODIFY `active` tinyint unsigned not null default 1
    SQL
    execute <<-SQL
      ALTER TABLE `routes`
        MODIFY `id` mediumint unsigned not null auto_increment
    SQL
    
    # Prepopulate
    Route.create([{:name => 'No routes selected'},{:name => 'Amy'}, {:name => 'Jared'}, {:name => 'Jim'}])
    
    
    # Replace column
    add_column :orders, :route_id, :integer, :after => :route_number
    execute <<-SQL
      UPDATE `orders` set
        `route_id` = (select `id` from `routes` where `name` = `route_number`)
    SQL
    
    execute <<-SQL
      UPDATE `orders` set
        `route_id` = (select `id` from `routes` where `name` = 'No routes selected')
      WHERE `route_id` IS NULL
    SQL
    
    remove_column :orders, :route_number
  end

  def down
    
    add_column :orders, :route_number, :string, :before => :route_id
    
    execute <<-SQL
      UPDATE `routes` set
        `route_number` = (select `name` from `routes` where `id` = `route_id`)
      WHERE
        `route_id` IS NOT NULL
    SQL
    
    remove_column :orders, :route_id
    
    drop_table :routes
    
  end
end
