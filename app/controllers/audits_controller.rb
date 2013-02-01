class AuditsController < ApplicationController
  def new
	store_id = params[:store_id]
	@audit = Store.find( store_id ).audit.build()
	@metrics = Metric.find(:all, :order => [:metric_grouping,:display_order])
  end

  def show
	audit_id = params[:audit_id]
	@page_title = "Audit for ... on ..."
	@audit = Audit.find(audit_id)
  end
  
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
