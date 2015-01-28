class Store < ActiveRecord::Base
  extend ::Geocoder::Model::ActiveRecord   
  include StoreSearchable
  include StoreImport
  
  attr_accessor :possible_duplicates, :not_a_duplicate
  
  # Associations
  belongs_to :company, counter_cache: true
  belongs_to :state, foreign_key: [:country, :state_code]
  
  belongs_to :region, counter_cache: true
  
  has_many :store_contacts

  has_many :orders
  
  has_many :audits

	has_one :last_audit, -> { order("created_at desc") }, :class_name => "Audit"

  accepts_nested_attributes_for   :region, :reject_if => proc {|r| r[:name].blank? }

  
  # Validations  
  validates_presence_of [:company_id, :name, :street_address, :city, :state_code]
  validates_associated :region
  validate  :nearby_stores , on: [:create, :update], unless: Proc.new { |store| !store.not_a_duplicate.nil? && !store.not_a_duplicate.to_i.zero? }
  

  # Callbacks
  geocoded_by :address, if: :street_address_changed?
  
  after_validation :geocode
  
  before_save  do |store|
    StoreContact.where(:store_id => store[:id]).destroy_all
  end
  
  def nearby_stores
    return if self[:company_id].nil? || self.address.nil? || self.address.blank?
    lat_lon = Geocoder.coordinates(self.address)
    
    # When a store is being created the :id for the store is going to be nil
    # which may cause the ES query to fail because of a nil value in the must_not
    # clause. However, the must_not clause is required to ignore the current record 
    # when this validation is being performed during an :update operation.     
    store_id = self[:id] || 0     
    
    # A filter is used instead of a query as it comes with less overhead as
    # compared to a match_all query or something similar.
    possible_dups = Store.__elasticsearch__.search \
    filter: {
      bool: {
        must: [
          {
            geo_distance: {
              distance: "0.5mi",
              "location" => {
                lat: lat_lon[0],
                lon: lat_lon[1]
              }            
            }
          },
          {
            term: {
              "company.id" => self[:company_id]
            }
          }
        ],
        must_not: [{
          term: {
            id: store_id
          }
        }]          
      }
    }    
    
    if !possible_dups.results.size.zero? 
      self.possible_duplicates = possible_dups.results.map{ |item| item[:_source]} 
      errors[:base] << "Possible duplicate entry"
    end
    
  end

  # Model Methods

  def completed_audits( limit = "0,25")
    audits.where({status: 1}).order("created_at desc").limit( limit ).includes(:audit_journal)    
  end
  
  def address
    Store.address( self )
  end
  
  def self.address(storeObject)
    return if storeObject[:street_address].blank?
    return_value = storeObject[:street_address].strip.titlecase
    return_value += ", " + storeObject[:suite].strip unless storeObject[:suite].blank?
    return_value += ", " + storeObject[:city].strip.titlecase
    return_value += ", " + storeObject[:state_code]
    return_value += " - " + storeObject[:zip].strip unless storeObject[:zip].blank?
    return_value += " (" + storeObject[:country] + ")" unless storeObject[:country] == "US"
    return return_value
  end
  
  def full_name
    return_value = self[:name]
    return_value += " Store# #{self[:store_number]}" unless self[:store_number].blank?
    return_value += " (#{self[:locality]})" unless self[:locality].blank?
    return return_value    
  end
  
  def location
    {lat: self[:latitude], lon: self[:longitude] }
  end

  def as_indexed_json(options={})
    self.as_json({
      only: [:id, :country, :state_code, :store_number],
      methods: [:address, :full_name, :location],
      include: {
        company: { only: [:id, :name] },
        state: { only: :state_name },
        last_audit: {only: [:id, :created_at], methods: [:score]},
        region: {only: [:id, :name]}
      }
    })
  end
end

