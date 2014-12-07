class State < ActiveRecord::Base
	
	self.primary_keys = [:country, :state_code]
	
	has_many :stores
	has_many :companies, -> { uniq } , :through => :stores
  
  def self.list_for_dropdown(country="US")
    self.where(:country => country).order([:country,:state_name]).select([:state_code, :state_name]).order(:state_name)
  end

end
