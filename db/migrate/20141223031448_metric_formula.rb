class MetricFormula < ActiveRecord::Migration
  def change
    add_column :metrics, :formula, :string, length: 255, after: :apply_points_per_item
    add_column :metrics, :response_type, :string, length: 30, nil: false, default: 'radio', after: :description
  end
end
