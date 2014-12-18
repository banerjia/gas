class PeopleUpdate < ActiveRecord::Migration
  def up    
    execute <<-SQL
      ALTER TABLE `people`
        MODIFY COLUMN `id` mediumint unsigned not null AUTO_INCREMENT
    SQL
  end
  
  def down 
    execute <<-SQL
      ALTER TABLE `people`
        MODIFY COLUMN `id` int not null AUTO_INCREMENT
    SQL
  end
    
end
