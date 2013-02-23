class AdjustMetricsFields < ActiveRecord::Migration
  def up
		execute <<-SQL
			ALTER TABLE `metrics`
				MODIFY `points` smallint unsigned not null default 1,
				MODIFY `display_order` smallint unsigned,
				MODIFY `allows_free_form` tinyint unsigned not null default 0,
				MODIFY `trigger_alert` tinyint unsigned not null default 0,
				MODIFY `include` tinyint unsigned not null default 1,
				MODIFY `reverse_options` tinyint unsigned not null default 0
		SQL
		
		execute <<-SQL
			ALTER TABLE `store_metrics`
				MODIFY `audit_id` bigint unsigned not null,
				MODIFY `metric_id` mediumint unsigned not null,
				MODIFY `point_value` smallint,
				MODIFY `include` tinyint unsigned not null default 1
		SQL
  end

  def down
  end
end
