class StoresController < ApplicationController

  def index
    company_id = params[:company_id]

    inclusions = {:last_audit => {:only => [:id,:score]}, 
    :pending_audit => {:only => [:id, :score]}}
    exceptions = [:company_id,
      :division_id,
      :street_address,
      :suite,:phone, 
      :created_at, 
      :updated_at]


      stores = Store.find(
      :all, 
      :conditions => {:company_id => company_id}, 
      :include => [:last_audit,:pending_audit,:company])

      return_value = Hash.new
      return_value[:number_of_stores] = stores.length
      # Company information is witheld at this time.
      # return_value[:company]= {:id => stores[0].company.id, :name => stores[0].company.name }
      return_value[:stores] = stores

      respond_to do |format|
        format.json {
          render :json => return_value.to_json(
          :include => inclusions,
          :except => exceptions
          )
        }

        format.xml {
          render :json => return_value.to_xml(
          :include => inclusions,
          :except => exceptions
          )
        }
        
        format.html { render :locals => {:stores => stores, :page_title => "Stores"}}
      end    
    end

    def show
      store_id = params[:id]

      inclusions = {:last_audit => {:only => [:id,:score]}, 
      :pending_audit => {:only => [:id, :score]},
      :company => {:only => [:id,:name]},
      :division => {:only =>[:id,:name]}}
      exceptions = [:division_id,:company_id]

      store = Store.find(:first,:conditions => {:id => store_id}, :include => [:last_audit,:pending_audit,:company,:division])
      
      page_title = store[:name].titlecase + " Dashboard"
      
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
        
        format.html { render :locals => {:page_title => page_title,:store => store}}
      end

    end

    def edit
    
      selected_store_id = params[:id]
      page_title = "Edit Store Information"

      selected_store = Store.find( selected_store_id )
      states = State.find(:all,:select => [:country, :state_code, :state_name], :order => [:country,:state_name])
      companies = Company.find(:all)
      
      
      
      
      respond_to do |format|
        format.html do           
          render :locals => {:store => selected_store, :page_title => page_title, :states => states, :companies => companies }
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
    
    def audits
      limit = params[:limit] || 25
      store_id = params[:id]
      
      audits = Store.find(store_id).completed_audits(limit).select([:id,:store_id,:score, :auditor_name, :store_rep, :created_at])
      return_value = Hash.new
      return_value[:audits] = audits
      respond_to do |format|
        format.json { render :json => return_value.to_json(
            :include => {:audit_journal => {:only => [:title, :body]}}
          ) }
      end
    end
    
    def new_audit
      page_title = "New Audit"
      respond_to do |format|
        format.html { render :locals => {:page_title => page_title}}
      end
    end

  end