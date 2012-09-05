ENV["RAILS_ENV"] = 'development'

# Load the rails application
require File.expand_path('../application', __FILE__)
# Initialize the rails application
Graeters::Application.initialize! do |config|
	config.gem( 
		'thinking-sphinx', :version => '2.0.13'
	)
end 
