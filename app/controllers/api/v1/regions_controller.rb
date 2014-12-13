module Api
  module V1
    class RegionsController < ApiController
      
      def index    
        respond_with Region.where({:company_id => params[:company_id]}).select([:id, :name]).order(:name)
      end
    end
  end
end