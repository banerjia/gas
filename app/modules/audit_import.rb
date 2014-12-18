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
    __elasticsearch__.client.bulk({
      index: __elasticsearch__.index_name,
      type: __elasticsearch__.document_type,
      body: prepare_records(audits)
    })
  end  
  
  def as_indexed_json(options={})
    self.as_json({
      only: [:id, :created_at, :has_unresolved_issues],
      methods: [:score, :total_score],
      include: {
        company: { only: [:id, :name] },
        store: { only: [:id], methods: [:full_name]},
        people: { only: [:id, :name]}
      }
    })
  end
  
  def self.index_refresh
    __elasticsearch__.client.indices.delete index: index_name rescue nil
    __elasticsearch__.client.indices.create index: index_name, body: { settings: settings.to_hash, mappings: mappings.to_hash}
    import
  end
end