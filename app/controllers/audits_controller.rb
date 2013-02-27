class AuditsController < ApplicationController
	def index
		redirect_to :action => :search
	end
	def new
		store_id = params[:store_id] || 301
		@audit = Audit.new({:store_id => store_id})
		@metrics = Metric.find(:all)
	end

	def show
		audit_id = params[:id]		
		@audit = Audit.find(:first, :conditions => { :id => audit_id }, :include => :store)
		@audit_metrics = StoreMetric.find( :all, :conditions => {:audit_id =>  audit_id}, \
											:joins => 'RIGHT OUTER JOIN `metrics` ON `store_metrics`.`metric_id` = `metrics`.`id`', \
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
