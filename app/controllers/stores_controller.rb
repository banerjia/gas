class StoresController < ApplicationController

  def index
    redirect_to :action => "search"
  end

  def show
    store_id = params[:id]

    inclusions = {
    :pending_audit => {:only => [:id, :score]},
    :company => {:only => [:id,:name]}}
    exceptions = [:company_id]

    store = Store.includes([:store_contacts, :company ]).find(store_id)

    @page_title = store[:name].titlecase + " Dashboard"

    respond_to do |format|
      format.json do
        return_value = Hash.new
        return_value[:details] = store
        render :json => return_value.to_json(
        :include => inclusions,
        :except => exceptions)
      end

      format.xml do
        render :xml => store.to_xml(
        :include => inclusions,
        :except => exceptions)		
      end

      format.html { render :locals => {:store => store}}
    end

  end

	def new
    new_store = nil
		if params[:company_id]
			company = Company.find( params[:company_id] )
			@page_title = "New Store for #{company[:name]}"
			new_store = company.stores.build()
		else
			@page_title = "New Store"
			new_store = Store.new
		end
    render :new, :locals => {:store => new_store}
	end

	def create
    @store = store_params
    new_store = Store.create(@store)
    if new_store.valid?
      flash[:message] = "New store for #{new_store.company[:name]} successfully created"
      redirect_to :action => "show", :id => new_store.id
    else
      flash[:warning] = "Could not add store. Please review your entry"
      @store = Store.new(store_params)
      render :action => "new"
    end
	end

  def edit
    selected_store_id = params[:id]
    @page_title = "Edit Store Information"

    selected_store = Store.find( selected_store_id )
    states = State.all.select([:country, :state_code, :state_name]).order([:country,:state_name])
    companies = Company.all.order([:name]).sort { |a,b| a[:name].sub(/^(the|a|an)\s+/i, '') <=> b[:name].sub(/^(the|a|an)\s+/i, '' )}

    respond_to do |format|
      format.html do           
        render :locals => {:store => selected_store, :states => states, :companies => companies }
      end
    end
  end

  def update
    selected_store_id = params[:id]
    selected_store = Store.find( selected_store_id )  

    if selected_store.update_attributes( store_params)
      flash[:notice] = "Store information updated."
      redirect_to :action => "show", :id => selected_store_id
    else
      flash[:warning] = "Could not update store information."        
    end    
  end

  def new_audit
    page_title = "New Audit"
    respond_to do |format|
      format.html { render :locals => {:page_title => page_title}}
    end
  end

  def search
    
    page = (params[:page] || 1).to_i.abs
    params[:per_page] = (params[:per_page] || $per_page).to_i.abs
    params[:per_page] = $per_page if params[:per_page] == 0

    stores_found = Store.search params                  
    
    respond_to do |format|
      format.json do
        return_value = Hash.new
        return_value[:stores] = stores_found[:results]
        return_value[:more_pages] = stores_found[:more_pages]
        return_value[:stores_found] = stores_found[:total]
        return_value[:aggs] = stores_found[:aggs]
        render :json => return_value.to_json(
        :include => $store_inclusions,
        :except => $exclusions + [:phone])
      end
      format.html do
        [:action, :controller, :format].each { |key| params.delete(key) }
        @stores = stores_found[:results]
        @aggs = stores_found[:aggs] 
        
        # HACK NOTE:
        # The following line has been conditional because putting the COMPANY_ID in 
        # the filter causes aggregations to list regions that are not relevant to 
        # search results. For example, most regions are currently defined for Krogers
        # but when a search is performed for Byerly stores the regions associated with 
        # Krogers still show up. So this is a hack for the time being till the 
        # ES query is fine tuned to avoid this problem.
        if @aggs[:regions].present? && params[:company_id].present? && !Store.where(["company_id = ? AND region_id IS NOT NULL", params[:company_id].to_i]).any?
          @aggs[:regions] = nil
        end
        # END HACK NOTE
        
        
        @more_pages = stores_found[:more_pages]
        if @stores.size > 0	
			      @page_title = @stores[0].company.name + " Stores in " + @stores[0].state.state_name           		  
            render "search_results", :locals => {\
              :options => params}
        else
		      @page_title = "Information Unavailable"
          render "search_results", :locals => {\
			        :options => params, \
			        :stores => nil}			
        end
      end
    end
  end

private
  def store_params
    params.require(:store).permit(:company_id, :region_id, :name, :locality, :street_address, :city, :county, :state_code, :zip, :country, :store_number, :phone, :store_contacts_attributes => [:name, :title, :phone, :email])
  end
end
