class MetricTrackResolution < ActiveRecord::Migration
  def change
  	add_column :metrics, :track_resolution, :boolean, default: true, null: false, after: :response_type
  end
end
