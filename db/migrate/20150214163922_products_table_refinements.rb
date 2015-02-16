class ProductsTableRefinements < ActiveRecord::Migration
  def change
  	reversible do |dir|
  		dir.up do 
         add_column :products, :from, :datetime, after: :available_from
         add_column :products, :till, :datetime, after: :available_till

         change_column :products, :active, :boolean, null: false, default: true

        Product.where("`available_from` IS NOT NULL && LENGTH(`available_from`) > 5").each do |product|
          product[:from] = Date.strptime(product[:available_from], "%m/%d/%Y")
          product.save
        end
        Product.where("`available_till` IS NOT NULL && LENGTH(`available_till`) > 5").each do |product|
          product[:till] = Date.strptime(product[:available_till], "%m/%d/%Y")
          product.save
        end

        remove_column :products, :available_till
        remove_column :products, :available_from

  		end
  		dir.down do
        add_column :products, :available_from, :string, limit: 10, after: :code
        add_column :products, :available_till, :string, limit: 10, after: :available_from

        Product.where("`from` IS NOT NULL").each do |product|
          product[:available_from] = product[:from].strftime("%m/%d/%Y")
          product.save
        end
        Product.where("`available_till` IS NOT NULL").each do |product|
          product[:available_till] = product[:till].strftime("%m/%d/%Y")
          product.save
        end

  			execute <<-SQL
				ALTER TABLE `products`
					MODIFY COLUMN `active` tinyint unsigned not null default 1
  			SQL

        remove_column :products, :from
        remove_column :products, :till
  		end
  	end
  end
end
