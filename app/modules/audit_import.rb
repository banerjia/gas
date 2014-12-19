module AuditImport
  def self.import
    Audit.includes([:company, :store]).find_in_batches do |audits|
      bulk_index(audits)
    end
  end

  def self.prepare_records(audits)
    audits.map do |audit|
      { index: { _id: audit.id, data: audit.as_indexed_json } }
    end
  end

  def self.bulk_index(audits)
    Audit.__elasticsearch__.client.bulk({
      index: __elasticsearch__.index_name,
      type: __elasticsearch__.document_type,
      body: prepare_records(audits)
    })
  end  
  
end
