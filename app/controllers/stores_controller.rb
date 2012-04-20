class StoresController < ApplicationController

  def index
  end

  def show
    store_id = params[:id]

    inclusions = {:last_audit => {:only => [:id,:score]}, 
    :pending_audit => {:only => [:id, :score]},
    :company => {:only => [:id,:name]},
    :division => {:only =>[:id,:name]}}
    exceptions = [:division_id,:company_id]

    store = Store.find(:first,:conditions => {:id => store_id}, :include => [:last_audit,:pending_audit,:company,:division])

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
    companies = Company.find(:all)      

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
    stores_found = nil
    company_id = params[:company_id]
    division_id = params[:division_id]
    state_code = params[:state]
    country = params[:country]
    
    page = params[:page] || 1
    page = page.to_i
    start_at = params[:start_at] || 0
    result_count = (params[:result_count] || 10).to_i

    conditions =  Hash.new
    with_options = Hash.new

    with_options[:company_id] = company_id unless company_id.nil?
    with_options[:division_id] = division_id unless division_id.nil?
    conditions[:state_code] =  state_code unless state_code.nil?
    # Only include country if state_code is specified.
    conditions[:country] = country || 'US' unless state_code.nil?

    stores_found = Store.search params[:q], \
                    :with => with_options, \
                    :conditions => conditions, \
                    :include => [:division, :pending_audit, :last_audit], \
                    :page => page, \
                    :per_page => result_count, \
                    :match_mode => :extended, \
                    :order => 'country ASC, state_name ASC, city ASC', \
                    :sort_mode => :extended
                    
    total_found = Store.search_count params[:q], \
                  :with => with_options, \
                  :conditions => conditions, \
                  :match_mode => :extended
                  
    total_pages = (total_found.to_f / result_count)

    return_value = Hash.new
    return_value[:stores] = stores_found
    return_value[:more_pages] = (total_pages > page)
    return_value[:stores_found] = stores_found.count
    conditions[:q] = params[:q] unless params[:q].nil?
    respond_to do |format|
      format.json do
        render :json => return_value.to_json(
        :include => $store_inclusions,
        :except => $exclusions + [:phone])
      end
      format.html do
        params.delete(:action)
        params.delete(:controller)
        params[:format] = :json
        if stores_found.count > 0
          if !division_id.nil?
            division_name = (!stores_found[0].division.nil? ? stores_found[0].division[:name] : "Unassigned")
            params[:division_id] = nil if stores_found[0].division.nil?
			@page_title = stores_found[0].company[:name] + " Stores in " + division_name + " Division"                 
            render "search_results", :locals => \
              {:stores => stores_found, :ajax_path => stores_search_path(params), :more_pages => return_value[:more_pages]}
          else	
			@page_title = stores_found[0].company[:name] + " Stores in " + stores_found[0].state[:state_name]              		  
            render "search_results", :locals => {\
              :stores => stores_found, \
              :ajax_path => stores_search_path(params),\
              :options => conditions.merge(with_options), :more_pages => return_value[:more_pages]}
          end
        else
		  @page_title = "Information Unavailable"
          render "search_results", :locals => {\
			        :options => conditions.merge( with_options ), \
			        :stores => nil}			
        end
      end
    end
  end
end
