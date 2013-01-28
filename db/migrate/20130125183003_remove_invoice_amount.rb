class RemoveInvoiceAmount < ActiveRecord::Migration
  def up
    remove_column :orders, :invoice_amount
  end

  def down
    add_column :orders, :invoice_amount, :decimal, :after => :store_id
  	execute <<-SQL
  		ALTER TABLE `orders` 
  			MODIFY `invoice_amount` decimal(10,2) unsigned not null default 0
  	SQL
  end
end
