class CompaniesController < ApplicationController
  $exceptions = [:updated_at, :created_at]
  $store_inclusions = {:last_audit => {:only => [:id, :score, :created_at,:auditor_name]},
    :pending_audit => {:only => [:id, :score, :created_at,:auditor_name]}}

  def index

    all_companies = Company.where( {:active => true }).order(:name)
    all_companies = all_companies.sort { |a,b| a[:name].sub(/^(the|a|an)\s+/i, '') <=> b[:name].sub(/^(the|a|an)\s+/i, '' )}

    @page_title = "Chains"
    return_value = Hash.new
    return_value[:number_of_companies] = all_companies.length
    return_value[:companies] = all_companies
    respond_to do |format|
      format.json { render :json => return_value.to_json(:except => $exceptions)}
      format.xml { render :xml => all_companies.to_xml(:except => $exceptions)}
      format.html { render :locals => {:companies => all_companies} }
    end    
  end

  def show
    company_id = params[:id]
    current_user_is_admin = true

    company = Company.find(company_id)

    @page_title = "Details for " + company[:name]

    return_value = Hash.new
    return_value[:details] = company
    respond_to do |format|
      format.json do
	return_value[:details][:states_with_stores] = company.states_with_stores
	render :json => return_value.to_json(
	  :except => $exceptions
	)
      end
      format.xml do 
	return_value[:details][:states_with_stores] = company.states_with_stores
	render :xml => return_value.to_xml(
	  :except => $exceptions
	)
      end

      format.html { render :locals => {:company => company, :current_user_is_admin => current_user_is_admin}}
    end

  end

  def edit
    company_id = params[:id]
    @page_title = "Edit Chain Details"

    company = Company.find(company_id)

    respond_to do |format|
      format.html {render :locals => {:company => company}}
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
      render :edit, :locals => {:company => company}
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

private
	def company_params
		params[:company].permit( :name, :active )
	end
end
