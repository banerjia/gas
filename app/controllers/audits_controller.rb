class AuditsController < ApplicationController
	def index
		redirect_to :action => :search
	end
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
		params[:page] ||=  1 
		params[:per_page] ||= $per_page
		params[:q] ||= "*"
		results = Audit.search_audits(params) 
		respond_to do |format|
			format.html do 
				# Sanitize params
				[:action, :controller, :format].each { |key| params.delete(key) }
				@page_title = 'Audits'
				@previous_search = params
				@search_results = results
			end
			format.json { render :json => results.to_json( :include => {:store => {:only => [:name], :methods => [:address]}} ) }
		end
	end
end
