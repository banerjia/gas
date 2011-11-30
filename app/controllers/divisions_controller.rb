class DivisionsController < ApplicationController

  def index
    company_id = params[:company_id]
    
    divisions = Division.where(:company_id => company_id)
    
    return_value = Hash.new
    return_value[:division_found] = divisions.length
    return_value[:divisions] = divisions
    respond_to do |format|
      format.json {render :json => return_value.to_json}
    end
    
  end
  
  def show
    
    
  end
  
  def new
    
  end
end