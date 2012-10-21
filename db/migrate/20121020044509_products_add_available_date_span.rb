class ProductsAddAvailableDateSpan < ActiveRecord::Migration
  def up
	change_table :products do |t|
		t.string :available_from, :limit => 10, :after => :code
		t.string :available_till, :limit => 10, :after => :available_from
	end
  end

  def down
	remove_column :products, [:available_from, :available_till]
  end
end
