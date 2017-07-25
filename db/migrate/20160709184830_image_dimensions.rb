require 'fastimage'
class ImageDimensions < ActiveRecord::Migration
  def change
    reversible do |dir|
      dir.up do 
        add_column :images, :width, :decimal, precision: 7, scale: 2, :after => :content_url
        add_column :images, :height, :decimal, precision: 7, scale: 2, :after => :width

        Image.where("(`width` IS NULL or `height` IS NULL) and `content_url` IS NOT NULL").each do |image|
          image_dimensions = FastImage.size(image[:content_url])
          Image.where({content_url: image[:content_url]}).update_all({width: image_dimensions[0], height: image_dimensions[1]}) unless image_dimensions.nil?
        end

        execute <<-SQL
				ALTER TABLE `images`
					MODIFY COLUMN `width` decimal(6,2) unsigned, 
          MODIFY COLUMN `height` decimal(6,2) unsigned
  			SQL


      end
      dir.down do 
        remove_column :images, :width
        remove_column :images, :height
      end
    end
  end
end
