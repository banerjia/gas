class Image < ActiveRecord::Base
    belongs_to :imageable, polymorphic: true  

    def content_url_size
        Image.dimensions(self[:content_url])
    end

    def self.dimensions(url)
        retval = "0x0"
        matches = /dim\-([0-9]+x[0-9]+)/.match(url)
        if !matches.nil?
            retval = matches[1]
        else
            url = "https:#{url}" unless url.index("http") == 0
            image_dimensions = FastImage.size(url)
            retval = "#{image_dimensions[0]}x#{image_dimensions[1]}" unless image_dimensions.nil?
        end

        return retval
    end

    def self.updateDims
        Image.where("`content_url` IS NOT NULL").each do |image|
            content_url = image[:content_url]
            content_url = "https:#{content_url}" unless content_url.index("http") == 0
            image_dimensions = FastImage.size(content_url)
            Image.where({content_url: image[:content_url]}).update_all({content_url_size: "#{image_dimensions[0]}x#{image_dimensions[1]}"}) unless image_dimensions.nil?
        end
    end
end
