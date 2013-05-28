require 'yaml'
AppConfig = YAML.load_file("config/custom_config.yml")
AppConfig.each do |key, value |
  ENV[key.to_s] = value.to_s
end
RAILS_ENV = ENV['RAILS_ENV']
#ENV['RAILS_ENV'] = 'development'
# Load the rails application
require File.expand_path('../application', __FILE__)
# Initialize the rails application

# This piece of code is placed here instead of an 
# initializer file because the environment variables for 
# the database need to be set before initializing 
# the mysql adapter settings

Graeters::Application.initialize! 
