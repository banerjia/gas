class AuditAuditorName < ActiveRecord::Migration
  def change
  	add_column :audits, :auditor_name, :string, limit: 30, after: :id
  	reversible do |dir|
  		dir.up do
  			remove_reference :audits, :person
  		end

  		dir.down do 
  			add_reference :audits, :person, index: true
  		end
  	end
  end
end
