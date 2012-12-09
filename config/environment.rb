# Load the rails application
require File.expand_path('../application', __FILE__)
# Initialize the rails application

# This piece of code is placed here instead of an 
# initializer file because the environment variables for 
# the database need to be set before initializing 
# the mysql adapter settings
AppConfig = YAML.load_file("#{Rails.root}/config/custom_config.yml")[Rails.env]
AppConfig.each do |key, value |
  ENV[key.to_s] = value.to_s
end


Graeters::Application.initialize! 
