class AuditMetricNeedResolution < ActiveRecord::Migration
  def change
  	reversible do |dir|
  		dir.up do 
  			execute <<-SQL
  				ALTER TABLE `audit_metrics`
  					CHANGE COLUMN `needs_resolution` `resolved` tinyint not null default 0
  			SQL
  		end

  		dir.down do
  			execute <<-SQL
  				ALTER TABLE `audit_metrics`
  					CHANGE COLUMN `resolved` `needs_resolution` tinyint not null default 0
  			SQL
  		end
  	end
  end
end
