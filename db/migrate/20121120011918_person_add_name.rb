class PersonAddName < ActiveRecord::Migration
  def up
	add_column :people, :name, :string, :limit => 100, :after => :id
  end

  def down
	remove_column :people, :name
  end
end
