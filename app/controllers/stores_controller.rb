class StoresController < ApplicationController

  def index
    redirect_to :action => "search"
  end

  def show
    store_id = params[:id]

    inclusions = {:last_audit => {:only => [:id,:score]}, 
    :pending_audit => {:only => [:id, :score]},
    :company => {:only => [:id,:name]}}
    exceptions = [:company_id]

    store = Store.find(:first, :conditions => {:id => store_id}, :include => [:store_contacts, :last_audit,:pending_audit,:company])

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

  def edit
    selected_store_id = params[:id]
    @page_title = "Edit Store Information"

    selected_store = Store.find( selected_store_id )
    states = State.find(:all,:select => [:country, :state_code, :state_name], :order => [:country,:state_name])
    companies = Company.find(:all, :order => [:name]).sort! { |a,b| a[:name].sub(/^(the|a|an)\s+/i, '') <=> b[:name].sub(/^(the|a|an)\s+/i, '' )}      

    respond_to do |format|
      format.html do           
        render :locals => {:store => selected_store, :states => states, :companies => companies }
      end
    end
  end

  def update  
    selected_store_id = params[:id]
    selected_store = Store.find( selected_store_id )  

    if selected_store.update_attributes( params[:store])
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
    
    page = (params[:page] || 1).to_i
    params[:per_page] = (params[:per_page] || $per_page).to_i

    stores_found = Store.search params                  
    
    respond_to do |format|
      format.json do
        return_value = Hash.new
        return_value[:stores] = stores_found[:results]
        return_value[:more_pages] = stores_found[:more_pages]
        return_value[:stores_found] = stores_found[:total]
        return_value[:facets] = stores_found[:facets]
        render :json => return_value.to_json(
        :include => $store_inclusions,
        :except => $exclusions + [:phone])
      end
      format.html do
        [:action, :controller, :format].each { |key| params.delete(key) }
        @stores = stores_found[:results]
        @facets = stores_found[:facets]
        @more_pages = stores_found[:more_pages]
        if @stores.size > 0	
			      @page_title = @stores[0].company[:name] + " Stores in " + @stores[0].state[:state_name]              		  
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
end
