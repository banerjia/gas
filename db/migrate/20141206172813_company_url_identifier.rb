class CompanyUrlIdentifier < ActiveRecord::Migration
  def change
    add_column :companies, :url_part, :string, :size => 20, :after => :name
    
    add_index :companies, :url_part, :unique => true
    add_index :companies, [:active, :url_part]
    
    Company.all do |company|  
      # Replace the spaces and special characters at the very end of the chain. This will facilitate
      # the removal of English articles and words less than 3 characters
      company[:url_part] = company[:name].downcase.gsub(/\b(the|a|an|\w{1,2})\b/,'').gsub(/[^a-z0-9]/, '')
      company.save
    end
    
  end
end
