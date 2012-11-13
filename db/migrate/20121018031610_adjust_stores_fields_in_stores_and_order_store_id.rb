class AdjustStoresFieldsInStoresAndOrderStoreId < ActiveRecord::Migration
  def up

	execute <<-SQL
		ALTER TABLE `orders`
			CHANGE COLUMN `store_id` `store_id` bigint(20) unsigned not null
	SQL
  end

  def down
  end
end
