class StoresController < ApplicationController

  def index
    redirect_to action: "search"
  end

  def show

    store_id = params[:id]

    store = Store.includes([:store_contacts, :company, :region ]).find(store_id)
    session[:last_page] = request.env['HTTP_REFERER'] || nil \
        unless \
          request.env['HTTP_REFERER'] == new_store_url \
          || request.env['HTTP_REFERER'] == edit_store_url(store)

    @page_title = "Store: #{store[:name]}"

    respond_to do |format|
      format.html { render locals: {store: store, recent_audits: store.audits.order(created_at: :desc).limit(5), recent_orders: store.orders.order(created_at: :desc).limit(5)}}
    end

  end

	def new
    session[:last_page] = request.env['HTTP_REFERER'] || nil

    new_store = nil
		@page_title = "Add a Store"
    
    new_store = Store.new({not_a_duplicate: false})
    
		if params[:company_id]
			company_values = Company.where( {id: params[:company_id]} ).pluck(:id, :name).first
      company_id, company_name = company_values
			
      new_store[:company_id] = company_id
		end
    
    render locals: {store: new_store}
	end

	def create
    store = store_params
    store[:region_attributes][:company_id] = store[:company_id]
    
    new_store = Store.create(store)
    if new_store.valid?
      flash[:message] = "New store for #{new_store.company[:name]} successfully created"
      redirect_to store_path(new_store)
    else
      @page_title = "Add a Store"      
      render action: "new", locals: {store: new_store}
    end
	end

  def edit
    selected_store_id = params[:id]
    @page_title = "Update a Store"

    selected_store = Store.find( selected_store_id )
    states = State.all.select([:country, :state_code, :state_name]).order([:country,:state_name])
    companies = Company.all.order([:name]).sort { |a,b| a[:name].sub(/^(the|a|an)\s+/i, '') <=> b[:name].sub(/^(the|a|an)\s+/i, '' )}

    respond_to do |format|
      format.html do           
        render locals: {store: selected_store, states: states, companies: companies }
      end
    end
  end

  def update
    selected_store_id = params[:id]
    store_to_update = Store.find( selected_store_id )  
    store_to_update.update_attributes( store_params )
    if store_to_update.valid?
      flash[:notice] = "Store information updated."
      redirect_to store_path(store_to_update)
    else      
      render action: "edit", locals: {store: store_to_update}     
    end    
  end

  def destroy
    selected_store_id = params[:id]
    store_to_delete = Store.find( selected_store_id)

    store_to_delete.update_columns({active: false})
    
    store_to_delete.__elasticsearch__.delete_document

    #   ##############################################################
    #   ## TO DO: 
    #   ## - Remove related index enteries for Orders and Audits
    #   ## - Streamline the delete process to delete stores that have no related entries
    #   ##    If there are related entries in Orders and Audits table then mark the store inactive
    #   ##############################################################
    # if store_to_delete.audits.size > 0 || store_to_delete.orders.size > 0
    #   store_to_delete[:active] = false
    #   store_to_delete.save
    #   store_to_delete.__elasticsearch__.delete_document
    #   store_to_delete.orders.__elasticsearch__.delete_document # - this does not work
    #   store_to_delete.audits.__elasticsearch__.delete_document # - this does not work
    # else
    #   store_to_delete.destroy
    # end

    respond_to do |format|
      format.json do
        render json: {success: true}.to_json
      end
    end 
  end

  def search
    
    page = (params[:page] || 1).to_i.abs
    params[:per_page] = (params[:per_page] || $per_page).to_i.abs
    params[:per_page] = $per_page if params[:per_page] == 0
    params[:page] = page

    stores_found = Store.search params   
    aggs = stores_found[:aggs]               
    
    respond_to do |format|
      # format.json do
      #   return_value = Hash.new
      #   return_value[:stores] = stores_found[:results]
      #   return_value[:more_pages] = stores_found[:more_pages]
      #   return_value[:stores_found] = stores_found[:total]
      #   return_value[:aggs] = stores_found[:aggs]
      #   render json: return_value.to_json(
      #   include: $store_inclusions,
      #   except: $exclusions + [:phone])
      # end
      format.html do
        [:action, :controller, :format].each { |key| params.delete(key) }
        
        # HACK NOTE:
        # The following line has been conditional because putting the COMPANY_ID in 
        # the filter causes aggregations to list regions that are not relevant to 
        # search results. For example, most regions are currently defined for Krogers
        # but when a search is performed for Byerly stores the regions associated with 
        # Krogers still show up. So this is a hack for the time being till the 
        # ES query is fine tuned to avoid this problem.
        if aggs[:regions].present? && params[:company_id].present? && !Store.where(["company_id = ? AND region_id IS NOT NULL", params[:company_id].to_i]).any?
          aggs[:regions] = nil
        end
        # END HACK NOTE
        
        
        if stores_found[:results].size > 0	
			      @page_title = "Store Listing"    
            @page_title = "#{@page_title} for #{stores_found[:results].first.company.name}" if params[:company_id].present? 
            @browser_title = "#{stores_found[:results].first.company.name} Stores" if params[:company_id].present?      		  
            render "search_results", locals: {stores_found: stores_found[:results], total_results: stores_found[:total], aggs: stores_found[:aggs] , options: params}
        else
		      @page_title = "Information Unavailable"
          render "search_results", locals: {options: params, stores_found: nil, total_results: 0, aggs: nil}			
        end
      end
    end
  end

private
  def store_params
    # if params[:store][:region_id].nil? || params[:store][:region_id].blank?
    #   params[:store][:region_attributes][:company_id] = params[:store][:company_id]
    # else
    #   params[:store][:region_attributes] = nil
    # end
    params.require(:store).permit(:not_a_duplicate, :company_id, :region_id, :name, :locality, :street_address, :city, :county, :state_code, :zip, :country, :store_number, :phone, store_contacts_attributes: [:name, :title, :phone, :email], region_attributes: [:name, :company_id])
  end
end
