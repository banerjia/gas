class ImagesUpdate < ActiveRecord::Migration
	def change
		add_column :images, :content_type, :string, limit: 150, after: :imageable_type
		add_column :images, :content_url, :string, limit: 1024, after: :content_type

		reversible do |dir|
			dir.up do 
				[:image_type, :file].each do |col|
					remove_column :images, col
				end
			end
			dir.down do 
				add_column :images, :image_type, :string, limit: 20, after: :imageable_type
				add_column :images, :file, :string, limit: 255, after: :image_type
			end
		end
	end
end
