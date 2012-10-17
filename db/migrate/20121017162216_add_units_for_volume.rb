class AddUnitsForVolume < ActiveRecord::Migration
  def up
	create_table :volume_units do |t|
		t.string :name, :limit => 20, :null => false
		t.timestamps
	end

	execute <<-SQL
		ALTER TABLE `volume_units`
			CHANGE COLUMN `id` `id` smallint(11) unsigned not null auto_increment
	SQL

	execute <<-SQL
		INSERT `volume_units` (`name`) VALUES( 'Pint')
	SQL

	change_table :product_orders do |t|
		t.references :volume_unit, :after => :quantity
	end

	execute <<-SQL
		ALTER TABLE `product_orders` 
			CHANGE COLUMN `volume_unit_id` `volume_unit_id` smallint(11) unsigned not null default 1 after `quantity`
	SQL

	add_index :product_orders, [:volume_unit_id, :quantity]
  end

  def down
	remove_index :product_orders, [:volume_unit_id, :quantity]
	execute <<-SQL
		ALTER TABLE `product_orders`
			DROP COLUMN `volume_unit_id`
	SQL

	drop_table :volume_units
  end
end
