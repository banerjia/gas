class CompanyRemoveDivisionCount < ActiveRecord::Migration
  def up
    remove_column :companies, :divisions_count
  end

  def down
    add_column :companies, :divisions_count, :integer, :null => false, :default => 0
  end
end
