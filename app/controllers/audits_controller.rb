class AuditsController < ApplicationController
	def index
		redirect_to action: :search
	end
	def new
		store_id = params[:store_id] 
		store = Store.find(store_id)
		metrics_to_use = Metric.includes(:metric_options).active_metrics.order([:display_order])
		new_audit = store.audits.build
		
		# Building the entire audit_metric and audit_metric_response structure here
		# will eliminate the need to call .build for each of the field_for associations in the 
		# layout. This in turn will make the template more flexible to be used with 
		# the initial render and when the template is called in case any of the model
		# validations fail. There is no SQL overhead when this action is performed in
		# the controller. However, there is a possibility that this action may require
		# more memory.
		metrics_to_use.each do |m|
			am = new_audit.audit_metrics.build({metric_id: m[:id]})
			m.metric_options.sort{ |a,b| a[:display_order]<=>b[:display_order]}.each do |mo|
				am.audit_metric_responses.build({metric_option_id: mo[:id]})
			end
		end

		respond_to do |format|
			format.html do
				@page_title = "New Audit"
				render locals: { audit: new_audit, metrics: metrics_to_use }
			end
		end
		
	end
	
	def create    
		audit = Audit.new( audit_params )
		audit[:loss] = audit[:loss].abs
		audit.save! #unless audit.total_score == 0

		if audit.total_score == 0 || audit.valid?
			flash[:notice] = audit.total_score == 0 ? 'Empty audits was not saved' : 'New audit recorded'
			redirect_to store_path(audit[:store_id])
		else
			flash[:warning] = 'Error processing audit'
			metrics_to_use = Metric.includes(:metric_options).active_metrics.order([:display_order])
			new_audit = Store.find( params[:audit][:store_id]).audits.build(audit_params)
			audit_params[:audit_metrics_attributes].each_with_index do |am, index|
			 	tmp = new_audit.audit_metrics.build(am.second)
			 	if !metrics_to_use[index].metric_options.size.zero? && tmp.audit_metric_responses.size.zero?
			 		metrics_to_use[index].metric_options.each_with_index do |amr, amr_index|
			 			# TO DO: 
			 			# Update code to rebuild the response set to cover scenarios where some options
			 			# in between other options were not entered in the original form. This does not
			 			# apply to the current version of the audit form but it may be needed in future
			 			# iterations. One possible solution will be to remove it from audit_params (am)
			 			# before audit_metrics.build and then attach it back here after synchronizing
			 			# with metric_options

			 			tmp.audit_metric_responses.build({metric_option_id: amr[:id]})

			 		end
			 	end
			end
			new_audit.store[:store_number] = audit_params[:store_attributes][:store_number]
			
			render :new, locals: { audit: new_audit, metrics: metrics_to_use, audit_errors: audit}
		end
	end

	def edit
		@audit = Audit.find( :all, conditions: {id: params[:id]}, include: [:store, store_metrics: [:metric] ], joins: {store_metrics: [:metric]} ).first()
		@store = @audit.store
		@metrics = @audit.store_metrics.group_by{ |store_metric| store_metric.metric[:category] }.sort
	end

	def show
		audit_id = params[:id]		
		@audit = Audit.find(:first, conditions: { id: audit_id }, include: :store)
		@audit_metrics = StoreMetric.find( :all,  \
			joins: 'RIGHT JOIN `metrics` ON `metrics`.`id` = `store_metrics`.`metric_id` AND `store_metrics`.`audit_id` = ' + audit_id, \
			select: '`store_metrics`.`metric_id`, `store_metrics`.`point_value`, `store_metrics`.`include`, `store_metrics`.`resolved_at`, `metrics`.`title`, `metrics`.`description`, `metrics`.`category`, `metrics`.`quantifier`, `metrics`.`include`, `metrics`.`reverse_options`', \
			order: '`metrics`.`category`, `metrics`.`display_order`')
		@page_title = "Audit for #{@audit.store[:name]}"		
	end

	def search
		params[:page] ||=  1 
		params[:per_page] ||= $per_page
		params[:q] ||= "*"
		results = Audit.search(params) 
		respond_to do |format|
			format.html do 
				# Sanitize params
				[:action, :controller, :format].each { |key| params.delete(key) }
				@page_title = 'Audits'
				@previous_search = params
				@search_results = results
			end
			format.json { render json: results.to_json( include: {store: {only: [:name], methods: [:address]} }, methods: [:comments] ) }
		end
	end
	
	private
	
	def audit_params
		params
			.require(:audit)
			.permit(
				:base, 
				:loss, 
				:bonus, 
				:person_id, 
				:store_id, 
				:audit_comment, 
				:image_upload, 
				audit_metrics_attributes: [
					:metric_id, 
					:score_type, 
					:score, 
					:needs_resolution, 
					audit_metric_responses_attributes: [
						:metric_option_id,
						:selected, 
						:entry_value
					]
				], 
				store_attributes: [
					:id, 
					:store_number
				]
			)
	end
end
