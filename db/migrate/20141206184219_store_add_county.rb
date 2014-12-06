class StoreAddCounty < ActiveRecord::Migration
  def change
    add_column :stores, :county, :string, :size => 50, :after => :city
  end
end
