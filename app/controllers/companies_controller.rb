class CompaniesController < ApplicationController
  $exceptions = [:updated_at, :created_at]
  $store_inclusions = {:last_audit => {:only => [:id, :score, :created_at,:auditor_name]},
  :pending_audit => {:only => [:id, :score, :created_at,:auditor_name]}}

  def index
    all_companies = Company.find(:all, :order => :name)
    return_value = Hash.new
    return_value[:number_of_companies] = all_companies.length
    return_value[:companies] = all_companies
    respond_to do |format|
      format.json { render :json => return_value.to_json(:except => $exceptions)}
      format.xml { render :xml => all_companies.to_xml(:except => $exceptions)}
      format.html { render :locals => {:page_title => "Companies", :companies => all_companies} }
    end    
  end

  def show
    company_id = params[:id]
    current_user_is_admin = true

    company = Company.find(company_id)

    page_title = "Company Details for " + company[:name]

    return_value = Hash.new
    return_value[:details] = company
    respond_to do |format|
      format.json do
        return_value[:details][:states_with_stores] = company.states_with_stores
        render :json => return_value.to_json(
        :include => {:divisions => {:only => [:id, :name, :number_of_stores]}},
        :except => $exceptions
        )
      end
      format.xml do 
        return_value[:details][:states_with_stores] = company.states_with_stores
        render :xml => return_value.to_xml(
        :except => $exceptions
        )
      end

      format.html { render :locals => {:page_title => page_title, :company => company, :current_user_is_admin => current_user_is_admin}}
    end

  end

  def edit
    company_id = params[:id]
    page_title = "Edit Company Details"

    company = Company.find(company_id, :include => :divisions)
    company.divisions.new

    respond_to do |format|
      format.html {render :locals => {:page_title => page_title,:company => company}}
      format.json {render :json => company.to_json}
    end
  end
  
  def update
    company_id = params[:id]
    company = Company.find(company_id)
    if company.update_attributes(params[:company])
      flash[:notice] = "The information for " + company[:name] + " has been updated."
      redirect_to :action => "show", :id => company_id
    else
      flash[:warning] = "Company information could not be updated"
      render :edit, :locals => {:page_title => "Edit Company Details",:company => company}
    end    
  end

  def stores_snippet  
    company_id = params[:id]
    limit = params[:limit]

    # Assigning the :include information in a single local variable
    # helps in providing the same information for both JSON and XML
    # format.
    inclusions = $store_inclusions

    stores = Store.find(:all, 
    :conditions => {:company_id => company_id},
    :include => [:last_audit, :pending_audit],
    :limit => limit)

    return_value = Hash.new
    return_value[:number_of_stores] = stores.length
    return_value[:stores] = stores

    respond_to do |format|
      format.json do
        render :json => return_value.to_json(
        :except => $exceptions,
        :include => inclusions)
      end

      format.xml do 
        render :xml => return_value.to_xml(
        :except => $exceptions,
        :include => inclusions)
      end
    end  
  end
  
  def company_states
    company_id = params[:company_id]

    company = Company.find(company_id)

    return_value = Hash.new
    return_value[:states] = company.states_with_stores

    respond_to do |format|
      format.json {render :json => return_value.to_json}
    end
  end

end