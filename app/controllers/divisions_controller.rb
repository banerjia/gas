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
  
  def stores
    division_id = params[:id]
    
    stores = Store.find(:all,
                        :conditions => {:division_id => division_id})
    
    return_value = Hash.new
    return_value[:stores] = stores
    respond_to do |format|
      format.json do
        render :json => return_value.to_json(
          :include => $store_inclusions,
          :except => [:division_id, :company_id, :phone, :street_address,:suite, :zip_code, :created_at, :updated_at])
      end
    end
  end
  
  def stores_in_state
    division_id = params[:division_id]
    state_code = params[:state]
    
    stores = Store.find(:all,
                        :conditions => {:division_id => division_id,:state_code => state_code})
    
    return_value = Hash.new
    return_value[:stores] = stores
    
    respond_to do |format|
      format.json do
        render :json => return_value.to_json(
          :include => $store_inclusions,
          :except => [:division_id, :company_id, :phone, :street_address,:suite, :zip_code, :created_at, :updated_at])
      end
    end
  end
end