class AuditUnionStore < ActiveRecord::Migration
  def change
        reversible do |dir|
            dir.up do
                add_column :audits, :is_union, :boolean, nil: true, :after => :bonus
                add_column :audits, :merc_product, :boolean, nil: true, :after => :is_union

                execute <<-SQL
                            UPDATE `audits` SET
                                is_union = 0,
                                merc_product = 0
                        SQL

                change_column :audits, :is_union, :boolean, nil: false, default: false
                change_column :audits, :merc_product, :boolean, nil: false, default: false
            end

            dir.down do
                remove_column :audits, :is_union
                remove_column :audits, :merc_product
            end
        end
  end
end
