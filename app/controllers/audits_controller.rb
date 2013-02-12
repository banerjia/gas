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
    results = Audit.search_audits(params) 
    respond_to do |format|
      format.json { render :json => results.to_json }
    end
  end
end
