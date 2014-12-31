class MetricFinalRefinements < ActiveRecord::Migration
  def change
  	add_column :metrics, :metric_options_count, :integer, null: false, default: 0, after: :response_type

  	reversible do |dir|
  		dir.up do 
  			change_column :audit_metric_responses, :selected, :boolean, null: true, default: nil
  			execute <<-SQL 
  				ALTER TABLE `metrics`
  					MODIFY COLUMN `metric_options_count` tinyint unsigned not null default 0,
  					MODIFY COLUMN `display_order` tinyint unsigned not null default 1
  			SQL

  			execute <<-SQL
  				UPDATE `metrics` SET `metric_options_count` = 
  					(SELECT COUNT(`id`) FROM `metric_options` WHERE `metric_id` = `metrics`.`id`)
  			SQL
  		end

  		dir.down do
  			change_column :audit_metric_responses, :selected, :boolean, null: false, default: true
  			execute <<-SQL 
  				ALTER TABLE `metrics`
  					MODIFY COLUMN `display_order` smallint unsigned not null default 1
  			SQL
  		end
  	end
  end
end
