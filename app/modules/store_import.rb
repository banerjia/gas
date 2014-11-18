module StoreImport
  def self.import
    Store.includes([:company, :state, :region]).find_in_batches do |stores|
      bulk_index(stores)
    end
  end

  def self.prepare_records(stores)
    stores.map do |store|
      { index: { _id: store.id, data: store.as_indexed_json } }
    end
  end

  def self.bulk_index(stores)
    Store.__elasticsearch__.client.bulk({
      index: Store.__elasticsearch__.index_name,
      type: Store.__elasticsearch__.document_type,
      body: prepare_records(stores)
    })
  end

end