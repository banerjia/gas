require 'aws/s3'
class SaveOrdersToS3
	@queue = :graeters 

	def self.perform( order_id )
		order = Order.find( order_id, :include => [:product_orders => [:product, :volume_unit]] )
    		view_context = ActionView::Base.new(ActionController::Base.view_paths, {})
		data_to_write_to_s3 = view_context.render( :template => 'orders/show_order', :handlers => [:axlsx], :locals => {:order => order} )
		AWS::S3::Base.establish_connection!(
			:access_key_id		=> ENV['aws_access_key_id'],
			:secret_access_key	=> ENV['aws_secret_access_key']
		)

		AWS::S3::S3Object.store( "orders/Order_id_#{order_id}.xlsx", data_to_write_to_s3, 'ab_graeters_assets' )
	end
end
