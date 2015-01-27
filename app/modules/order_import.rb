module OrderImport
  def self.import
    Order.find_in_batches do |orders|
      bulk_index(orders)
    end
  end

  def self.prepare_records(orders)
    orders.map do |order|
      { index: { _id: order.id, data: order.as_indexed_json } }
    end
  end

  def self.bulk_index(orders)
    Order.__elasticsearch__.client.bulk({
      index: Order.__elasticsearch__.index_name,
      type: Order.__elasticsearch__.document_type,
      body: prepare_records(orders)
    })
  end

end