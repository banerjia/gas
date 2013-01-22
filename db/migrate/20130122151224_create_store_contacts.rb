class CreateStoreContacts < ActiveRecord::Migration
  def up
	create_table :store_contacts, :id => false do |t|
		t.integer :store_id, :null => false
		t.string :name,  :limit => 100
		t.string :title, :limit => 150
		t.string :phone, :limit => 20
		t.string :email, :limit => 255
		t.timestamps
	end
	
	execute <<-SQL
		ALTER TABLE `store_contacts` MODIFY store_id bigint unsigned not null
	SQL
	
	add_index :store_contacts, :store_id
  end

  def down
	remove_index :store_contacts, :store_id
	drop_table :store_contacts
  end
end
