class RemoveStoreDefaults < ActiveRecord::Migration
  def up
    change_column :stores, :state_code, :string, :default => nil
  end
  
  def down
    change_column :stores, :state_code, :string, :default => 'OH'
  end
end
