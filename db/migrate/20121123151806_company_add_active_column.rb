class CompanyAddActiveColumn < ActiveRecord::Migration
  def up
    add_column :companies, :active, :boolean, :null => false, :default => true, :after => :stores_count
    
    execute <<-SQL
      ALTER TABLE `companies`
        MODIFY `active` tinyint unsigned not null default 1
    SQL
  end

  def down
    remove_column :companies, :active
  end
end
