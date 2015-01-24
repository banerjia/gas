class ImagesProcessedFlag < ActiveRecord::Migration
  def change
	add_column :images, :processed, :boolean, null: false, default: false, after: :content_url

	add_index :images, :processed  	
  end
end
