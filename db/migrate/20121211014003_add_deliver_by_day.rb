class AddDeliverByDay < ActiveRecord::Migration
  def up
	add_column :orders, :deliver_by_day, :string, :limit => 10, :default => 'Monday', :after => :delivery_date
  end

  def down
	remove_column :orders, :deliver_by_day
  end
end
