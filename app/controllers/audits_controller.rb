class AuditsController < ApplicationController
	def index
		redirect_to action: :search
	end
	def new
		new_audit = Audit.new

		if(params[:store_id].present?)
			store_id = params[:store_id] 
			store = Store.find(store_id)
			new_audit = store.audits.build
		else
			new_audit.build_store()
		end

		new_audit.comments.build()

		metrics_to_use = Metric.includes(:metric_options).active_metrics.order([:display_order])
		
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
				am.audit_metric_responses.build({metric_option_id: mo[:id], selected: false})
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

		if audit.save
			flash[:notice] = 'New audit saved'
			redirect_to store_path(audit[:store_id])
		else
			flash[:warning] = 'Error processing audit'
			metrics_to_use = Metric.includes(:metric_options).active_metrics.order([:display_order])
			audit.comments.build() unless audit.comments.count > 0
			#byebug
			render :new, locals: { audit: audit, metrics: metrics_to_use}
		end
	end

	def edit

		id = params[:id]

		audit = Audit.includes([:store, audit_metrics: [:metric, audit_metric_responses: [:metric_option]]]).find(id)
		audit.audit_metrics = audit.audit_metrics.sort{ |a, b| a.metric[:display_order] <=> b.metric[:display_order]}
		#metrics_to_use = Metric.includes(:metric_options).active_metrics.order([:display_order])

		audit.comments.build() unless audit.comments.count > 0
	
		render :edit, locals: {audit: audit}
	end

	def update
		audit = Audit.find( params[:id ])
		audit_params[:loss] = audit_params[:loss].to_i.abs

		if audit.update(audit_params)
			flash[:notice] = 'Audit Updated'
			redirect_to audit_path(audit)
		else			
			render :edit, locals: { audit: audit}
		end
				
	end

	def show

		id = params[:id]

		audit = Audit.includes([:store, audit_metrics: [:metric, audit_metric_responses: [:metric_option]]]).find(id)
		audit.audit_metrics = audit.audit_metrics.sort{ |a, b| a.metric[:display_order] <=> b.metric[:display_order]}		
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
				:id,
				:base, 
				:loss, 
				:bonus, 
				:person_id, 
				:store_id, 
				:image_upload, 
				:created_at,
				audit_metrics_attributes: [
					:metric_id, 
					:score_type, 
					:base, 
					:bonus,
					:loss,
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
				],
				comments_attributes: [
					:content
				]
			)
	end
end
