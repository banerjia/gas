class AddMoreInformationAboutOrders < ActiveRecord::Migration
  def up
	change_table :orders do |t|
		t.string :invoice_number, :limit => 20, :after => :id
		t.string :route_number, :limit => 5, :after => :fulfilled
		t.decimal :invoice_amount, :after => :store_id
	end

	execute <<-SQL
		ALTER TABLE `orders` 
			CHANGE COLUMN `invoice_amount` `invoice_amount` decimal(10,2) unsigned not null default 0
	SQL
  end

  def down
	remove_column :orders, [:invoice_amount, :route_number, :invoice_number]
  end
end
