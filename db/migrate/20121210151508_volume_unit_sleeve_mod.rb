class VolumeUnitSleeveMod < ActiveRecord::Migration
  def up
    change_table :volume_units do |t|
      t.change :multiplier, :decimal, :precision => 5, :scale => 3, :default => 0
    end
    rename_column :volume_units, :multiplier, :sleeve_conversion

  end

  def down
    change_table :volume_units do |t|
      t.change :sleeve_conversion, :integer, :default => 0
    end
    rename_column :volume_units, :sleeve_conversion, :multiplier
  end
end
