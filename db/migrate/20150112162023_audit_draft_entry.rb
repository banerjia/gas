class AuditDraftEntry < ActiveRecord::Migration
  def change
  	add_column :audits, :draft, :boolean, null: false, default: false, after: :bonus

  	add_index :audits, [:store_id, :draft]
  end
end
