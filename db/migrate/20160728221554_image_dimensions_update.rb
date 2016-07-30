class ImageDimensionsUpdate < ActiveRecord::Migration
    def change
        reversible do |dir|
            dir.up do 
                add_column :images, :content_url_size, :string, length: 50, after: :content_url
                add_column :images, :thumbnail_url, :string, length: 2000, after: :content_url_size

                Image.all.each do |image|
                    Image.where({content_url: image[:content_url]}).update_all({content_url_size: "#{image[:width]}x#{image[:height]}"})
                end

                remove_column :images, :width
                remove_column :images, :height
            end
            dir.down do 
                remove_column :images, :thumbnail_url
                remove_column :images, :content_url_size

                add_column :images, :width, :decimal, precision: 7, scale: 2, :after => :content_url
                add_column :images, :height, :decimal, precision: 7, scale: 2, :after => :width

                Image.where("(`width` IS NULL or `height` IS NULL) and `content_url` IS NOT NULL").each do |image|
                    content_url = image[:content_url]
                    content_url = "https:#{content_url}" unless content_url.index("http") == 0
                    image_dimensions = FastImage.size(content_url)
                    Image.where({content_url: image[:content_url]}).update_all({width: image_dimensions[0], height: image_dimensions[1]}) unless image_dimensions.nil?
                end

                execute <<-SQL
                    ALTER TABLE `images`
                        MODIFY COLUMN `width` decimal(6,2) unsigned, 
                        MODIFY COLUMN `height` decimal(6,2) unsigned
                SQL
            end
        end
    end
end
