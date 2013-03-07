class AuditsController < ApplicationController
	def index
		redirect_to :action => :search
	end
	def new
		store_id = params[:store_id] 
		store = Store.find( store_id )
		@metrics = Metric.find(:all, :order => [:category, :display_order])
		@audit = store.audits.build()
		@store_metrics = @audit.store_metrics.build()
		@page_title = "New Audit for #{store.name_with_locality}"
	end
	
	def create
		store = Store.find(params[:audit][:store_id])
		audit = store.audits.new( params[:audit] )
		if audit.save
			Audit.tire.index.refresh
			flash[:notice] = 'New audit recorded'
			redirect_to store_path(store)
		else
			@audit = Audit.new(params[:audit])
			@metrics = Metric.find(:all, :order => [:category, :display_order])
			@store_metrics = StoreMetric.new()
			@store_metrics_chosen = params[:audit][:store_metrics_attributes].map{ |key, value| value }

			render "new"
		end
	end

	def show
		audit_id = params[:id]		
		@audit = Audit.find(:first, :conditions => { :id => audit_id }, :include => :store)
		@audit_metrics = StoreMetric.find( :all,  \
											:joins => 'RIGHT JOIN `metrics` ON `metrics`.`id` = `store_metrics`.`metric_id` AND `store_metrics`.`audit_id` = ' + audit_id, \
											:select => '`store_metrics`.`metric_id`, `store_metrics`.`point_value`, `store_metrics`.`include`, `store_metrics`.`resolved_at`, `metrics`.`title`, `metrics`.`description`, `metrics`.`category`, `metrics`.`quantifier`, `metrics`.`include`, `metrics`.`reverse_options`', \
											:order => '`metrics`.`category`, `metrics`.`display_order`')
		@page_title = "Audit for #{@audit.store[:name]}"		
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
			format.json { render :json => results.to_json( :include => {:store => {:only => [:name], :methods => [:address]} }, :methods => [:comments] ) }
		end
	end
end
