class AuditsController < ApplicationController
  def search
    limit = params[:limit] || 25
    store_id = params[:store_id]
    
    audits = Store.find(store_id).completed_audits(limit).select([:id,:store_id,:score, :auditor_name, :store_rep, :created_at])
    return_value = Hash.new
    return_value[:audits] = audits
    respond_to do |format|
      format.json { render :json => return_value.to_json(
          :include => {:audit_journal => {:only => [:title, :body]}}
        ) }
    end    
  end
end