module Index  
  def self.refresh
    Store.__elasticsearch__.client.indices.delete index: Store.index_name rescue nil
     Store.__elasticsearch__.client.indices.create index: Store.index_name, body: { settings: Store.settings.to_hash, mappings: Store.mappings.to_hash}
     Store.import
  end 
end