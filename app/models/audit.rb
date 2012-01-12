class Audit < ActiveRecord::Base
  
  belongs_to :store
  
  has_many :metrics
  has_one :audit_journal
  
  def is_pending?
	  self[:status] == 0
  end
end