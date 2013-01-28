class ChangeSentFields < ActiveRecord::Migration
  def up
    rename_column :orders, :sent, :email_sent
    rename_column :orders, :sent_date, :email_sent_date
  end

  def down
    rename_column :orders, :email_sent, :sent
    rename_column :orders, :email_sent_date, :sent_date
  end
end
