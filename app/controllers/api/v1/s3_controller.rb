module Api
	module V1
		class S3Controller < ApiController
			def access_token
			  render json: {
			    policy:    s3_upload_policy(params[:bucket]),
			    signature: s3_upload_signature(params[:bucket]),
			    key:       ENV['AWS_ACCESS_KEY_ID']
			  }
			end

			protected

			  def s3_upload_policy(bucket = nil)
			    create_s3_upload_policy(bucket)
			  end

			  def create_s3_upload_policy(bucket = nil)
			    Base64.encode64(
			      {
			        "expiration" => 1.hour.from_now.utc.xmlschema,
			        "conditions" => [ 
			          { "bucket" =>  bucket || ENV['aws_s3_bucket_upload'] },
			          [ "starts-with", "$key", "" ],
			          { "acl" => "public-read" },
			          [ "starts-with", "$Content-Type", "image" ],
			          [ "content-length-range", 0, 10 * 1024 * 1024 ]
			        ]
			      }.to_json).gsub(/\n/,'')
			  end

			  def s3_upload_signature(bucket = nil)
			    Base64.encode64(OpenSSL::HMAC.digest(OpenSSL::Digest.new('sha1'), ENV['AWS_SECRET_ACCESS_KEY'], s3_upload_policy(bucket))).gsub("\n","")
			  end
		end
	end
end