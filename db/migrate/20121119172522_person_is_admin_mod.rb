class PersonIsAdminMod < ActiveRecord::Migration
  def up
	add_column :people, :is_admin, :boolean, :null => false, :default => false, :after => :salt
  end

  def down
	remove_column :people, :is_admin
  end
end
