class AdditionalVolumeUnitInformation < ActiveRecord::Migration
  def up
    add_column :volume_units, :unit_code, :string, :limit => 15, :null => false, :default => 'oz', :after => :name
    add_column :volume_units, :multiplier, :integer, :null => false, :default => 1, :after => :unit_code
    
    execute <<-SQL
      ALTER TABLE `volume_units`
        MODIFY `multiplier` smallint not null default 1
    SQL
  end

  def down
    remove_column :volume_units, [:unit_code, :multiplier]
  end
end
