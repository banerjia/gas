class UpdateCompanyColumnDefinition < ActiveRecord::Migration
  def change
  	reversible do |dir|
  		dir.up do
  			change_column :companies, :active, :boolean, nil: false, default: true
  		end
  		dir.down do
  			execute <<-SQL
  				ALTER TABLE `companies`
  					MODIFY COLUMN `active` tinyint unsigned NOT NULL DEFAULT 0
  			SQL
  		end
  	end
  end
end
