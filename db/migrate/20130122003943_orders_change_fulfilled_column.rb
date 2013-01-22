class OrdersChangeFulfilledColumn < ActiveRecord::Migration
  def up
    rename_column :orders, :fulfilled, :sent
  end

  def down
    rename_column :orders, :sent, :fulfilled
  end
end
