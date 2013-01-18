class FlagForOrderToS3 < ActiveRecord::Migration
  def up
	add_column :orders, :available_in_s3, :boolean, :null => false, :default => false, :after => :invoice_amount

	execute <<-SQL
		ALTER TABLE `orders` 
			MODIFY `available_in_s3` tinyint(1) unsigned not null default 0
	SQL
  end

  def down
	remove_column :orders, :available_in_s3
  end
end
