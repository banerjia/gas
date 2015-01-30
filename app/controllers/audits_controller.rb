class AuditsController < ApplicationController
	def index
		redirect_to action: :search
	end

	def new
		new_audit = Audit.new({created_at: Date.today})

		if(params[:store_id].present?)
			store_id = params[:store_id] 
			store = Store.find(store_id)
			new_audit = store.audits.build
		else
			new_audit.build_store()
		end

		new_audit[:created_at] = new_audit[:created_at].strftime("%m/%d/%Y")
		new_audit.comments.build()
		new_audit.images.build()

		metrics_to_use = Metric.includes(:metric_options).active_metrics.order([:display_order])
		
		# Building the entire audit_metric and audit_metric_response structure here
		# will eliminate the need to call .build for each of the field_for associations in the 
		# layout. This in turn will make the template more flexible to be used with 
		# the initial render and when the template is called in case any of the model
		# validations fail. There is no SQL overhead when this action is performed in
		# the controller. However, there is a possibility that this action may require
		# more memory.
		metrics_to_use.each do |m|
			am = new_audit.audit_metrics.build({metric: m})
			m.metric_options.sort{ |a,b| a[:display_order]<=>b[:display_order]}.each do |mo|
				amr = am.audit_metric_responses.build({metric_option: mo, selected: false})
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

			
			audit[:created_at] = audit[:created_at].strftime("%m/%d/%Y") unless audit[:created_at].nil? || audit[:created_at].blank?
			audit.comments.build() unless audit.comments.size > 0
			audit.images.build() unless audit.images.size > 0

			@page_title = "New Audit"
			render :new, locals: { audit: audit}
		end
	end

	def edit

		id = params[:id]

		audit = Audit.includes([:store, :comments, :images, audit_metrics: [:metric, audit_metric_responses: [:metric_option]]]).find(id)

		# Prepping the model for rendering purposes

		# The following format will ensure that any time information is ommitted from the 
		# date in the view
		audit[:created_at] = audit[:created_at].strftime("%m/%d/%Y")

		# Iterating through the audit metrics and making ensuring that the 
		# audit_metric_responses are sorted using the metric_option[:display_order]
		audit.audit_metrics.each_with_index do |audit_metric, index|
			audit.audit_metrics[index].audit_metric_responses = audit_metric.audit_metric_responses.sort{ |a, b| a.metric_option[:display_order] <=> b.metric_option[:display_order]}
		end

		# In case no comments and/or images were attached to the audit
		# create dummy ones so that the fields are rendered in the view. 
		# In case they are left blank during the update operation they will be rejected
		# as a result of the configuration of the accepts_nested_attributes
		audit.comments.build() unless audit.comments.size > 0
		audit.images.build() unless audit.images.size > 0
	
		

		@page_title = "Edit Audit"

		render :edit, locals: {audit: audit}
	end

	def update
		audit = Audit.find( params[:id ])

		if audit.update(audit_params)
			flash[:notice] = 'Audit Updated'
			redirect_to audit_path(audit)
		else			
			@page_title = "Edit Store"
			
			audit[:created_at] = audit[:created_at].strftime("%m/%d/%Y") unless audit[:created_at].nil? || audit[:created_at].blank?

			render :edit, locals: { audit: audit}
		end
				
	end

	def show

		id = params[:id]

		audit = Audit.includes([:store, :comments, :images, audit_metrics: [:metric, audit_metric_responses: [:metric_option]]]).find(id)
		
		@page_title = "Audit for #{audit.store.full_name}"

		render :show, locals: {audit: audit}	
	end

	def search
		params = (request.params || {}).clone
		params[:page] ||=  1 
		params[:per_page] ||= $per_page
		params = params.merge({sort: "created_at-desc"}) unless params[:sort].present?

		params[:start_date] = Date.strptime(params[:start_date], '%m/%d/%Y') if params[:start_date].present? && !params[:start_date].blank?
		params[:end_date] = Date.strptime(params[:end_date], '%m/%d/%Y') if params[:end_date].present? && !params[:end_date].blank?

		results = Audit.search(params) 

		# Sanitize params
		[:action, :controller, :format].each { |key| params.delete(key) }

		respond_to do |format|
			format.html do
				@page_title = "Audits"
				@page_title = @page_title + ' for ' + results[:results].first[:store].full_name if params[:store_id].present?
				render locals: {audits: results, options: params}
			end

			format.json do 
				render json: results.to_json
			end
		end
	end
	
	private
	
	def audit_params
		# The following line corrects the date input as received from the view
		# into something that Rails 4 TimeZone parser can understand. 
		params[:audit][:created_at] = Date.strptime(params[:audit][:created_at], '%m/%d/%Y').to_date unless params[:audit][:created_at].blank?
		ams = params[:audit][:audit_metrics_attributes].map{ |k| {loss: k.second[:loss], resolved: k.second[:resolved]}}
		params[:audit][:has_unresolved_issues] = (ams.select{ |i| !i[:loss].nil? && i[:loss].to_i != 0 && i[:resolved].to_i.zero?}.size > 0)
		params
			.require(:audit)
			.permit(
				:id,
				:base, 
				:loss, 
				:bonus, 
				:auditor_name, 
				:store_id, 
				:image_upload,
				:created_at,
				:has_unresolved_issues,
				audit_metrics_attributes: [
					:metric_id, 
					:score_type, 
					:base, 
					:bonus,
					:loss,
					:resolved, 
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
				],
				images_attributes:[
					:content_url
				]
			)
	end
end
