class RearrageOrderFields < ActiveRecord::Migration
  def up
    execute <<-SQL
      ALTER TABLE `orders`
        MODIFY `email_sent_date` datetime after `email_sent`,
        MODIFY `store_id` bigint unsigned not null after `id`,
        MODIFY `route_id` smallint unsigned after `delivery_dow`
    SQL
  end

  def down
  end
end
