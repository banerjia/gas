class AuditScoringModelChanges < ActiveRecord::Migration
  def change

		add_column :metrics, :score_type, :string, limit: 15, null: false, default: 'base', after: :display_order
		add_column :audit_metrics, :score_type, :string, limit: 15, null: false, default: 'base', after: :metric_id
		add_column :audit_metrics, :score, :integer, null: false, default: 0, after: :score_type

		add_column :metric_options, :points, :integer, null: false, default: 0, after: :label
		add_column :metric_options, :isBonus, :boolean, null: false, default: false, after: :points
		
		
		reversible do |dir|
			dir.up do
				execute <<-SQL
					ALTER TABLE `metric_options`
						MODIFY COLUMN `points` smallint not null default 0
				SQL
				
				execute <<-SQL
					ALTER TABLE `audit_metrics`
						MODIFY COLUMN `score` smallint not null default 0
				SQL
				
				[:group_score_with, :scoring_formula, :include].each do |col|
					remove_column :metrics, col
				end	
				
				[:base_score_value, :loss_score_value, :bonus_score_value, :expected_value_type].each do |col|
					remove_column :metric_options, col
				end
				
				[:base, :bonus, :loss].each do |col|
					remove_column :audit_metrics, col
				end
				
				
			end
			dir.down do
				add_column :metrics, :group_score_with, :integer, after: :display_order
				add_column :metrics, :include, :boolean, null: false, default: true, after: :group_score_with
				add_column :metrics, :scoring_formula, :string, limit: 255, after: :apply_points_per_item

				execute <<-SQL
					ALTER TABLE `metrics` 
						MODIFY COLUMN `group_score_with` mediumint unsigned
				SQL
				
				add_column :metric_options, :expected_value_type, :string, after: :label

				[:base_score_value, :loss_score_value, :bonus_score_value].reverse.each do |col|
					add_column :metric_options, col, :integer, default: 0, null: false, after: :expected_value_type
				end
				
				execute <<-SQL
					ALTER TABLE `metric_options` 
						MODIFY COLUMN `base_score_value` smallint unsigned default 0 not null,
						MODIFY COLUMN `bonus_score_value` smallint unsigned default 0 not null,
						MODIFY COLUMN `loss_score_value` smallint unsigned default 0 not null
				SQL
			end
		end
  end
end
