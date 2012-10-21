class RemoveTimestampsFromProductOrders < ActiveRecord::Migration
  def up
	remove_timestamps :product_orders
  end

  def down
	add_timestamps :product_orders
  end
end
