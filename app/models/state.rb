class State < ActiveRecord::Base
	
	set_primary_keys :country, :state_code
	
	has_many :stores, :foreign_key => [:country, :state_code]
	has_many :companies, :through => :stores, :uniq => :true
	

end