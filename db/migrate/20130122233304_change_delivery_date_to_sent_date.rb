class ChangeDeliveryDateToSentDate < ActiveRecord::Migration
  def up
    rename_column :orders, :delivery_date, :sent_date
  end

  def down
    rename_column :orders, :sent_date, :delivery_date
  end
end
