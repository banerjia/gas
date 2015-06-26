class Company < ActiveRecord::Base

  # Included to use store indexing features from within
  # the after_commit callback
  include StoreImport

  has_many :stores
  has_many :states, -> { uniq } , :through => :stores
  
  has_many :regions
  
  validates_presence_of :name, \
                        :message => "Company name cannot be blank. Please provide a company name."
  
  HUMANIZED_ATTRIBUTES = {
    :name => "Company name"
  }

  after_update do
    if :active_changed?
      if !self[:active]
        Store.__elasticsearch__.client.delete_by_query index: Store.index_name, body: {query: {term: {"company.id" => self[:id]}}}
        # TO DO - update ElasticSearch indices
        # Clean up audits - ask client if this is desired
        # Clean up orders - ask client if this is desired
      else
        stores = Store.where(company_id: self[:id])
        Store.__elasticsearch__.client.bulk({
          index: Store.__elasticsearch__.index_name,
          type: Store.__elasticsearch__.document_type,
          body: StoreImport.prepare_records(stores)
        })
      end

    end

  end
  
  def self.human_attribute_name(attr, options = {})
    HUMANIZED_ATTRIBUTES[attr.to_sym] || super
  end
  
  def states_with_stores
    Store.where({:company_id => self[:id]})
    .select("stores.country, stores.state_code, states.state_name, count(id) as `stores_count`")
    .order("stores.country, stores.state_code")
    .group("stores.country, stores.state_code")
    .joins(:state)
  end
  
  def self.list_for_dropdown
    self.where(:active => true).order(:name).select([:id, :name]).sort{ |a,b| a[:name].sub(/^(the|a|an)\s+/i, '') <=> b[:name].sub(/^(the|a|an)\s+/i, '' )}
  end
  
end
