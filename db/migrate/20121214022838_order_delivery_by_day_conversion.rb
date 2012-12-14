class OrderDeliveryByDayConversion < ActiveRecord::Migration
  def up
    add_column :orders, :delivery_dow, :integer, :after => :deliver_by_day
    
    execute <<-SQL
      ALTER TABLE `orders`
        MODIFY `delivery_dow` smallint unsigned
    SQL
    
    
    Order.all.each do |order|
      order[:delivery_dow] = Date::DAYS_INTO_WEEK[ order[:deliver_by_day].downcase.to_sym ]
    end
    
    remove_column :orders, :deliver_by_day
  end

  def down
    add_column :orders, :delivery_by_day, :string, :limit => 10, :after => :delivery_dow
    
    Order.all.each do |order|
      order[:deliver_by_day] = Date::DAYS_INTO_WEEK.invert[order[:delivery_dow]].to_s.capitalize
    end
    
    remove_column :orders, :delivery_dow
    
  end
end
