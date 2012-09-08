class State < ActiveRecord::Base
	
	self.primary_keys = [:country, :state_code]
	
	has_many :stores
	has_many :companies, :through => :stores, :uniq => :true	

end
