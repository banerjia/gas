class ApplicationController < ActionController::Base
  helper :all
  protect_from_forgery
  
  $store_inclusions = { :last_audit => {:only => [:id, :score, :created_at]},
                        :pending_audit => {:only => [:id, :score, :created_at,:auditor_name]}}
  $exclusions = [:created_at, :updated_at, :longitude, :latitude]
  
  $per_page = 10
  $audit_page_size = 50
  
  #before_filter :require_login, :except => [:not_authenticated]
  before_filter :set_cache_buster

  def set_cache_buster
    response.headers["Cache-Control"] = "no-cache, no-store, max-age=0, must-revalidate"
    response.headers["Pragma"] = "no-cache"
    response.headers["Expires"] = "Fri, 01 Jan 1990 00:00:00 GMT"
  end

  def not_authenticated
     redirect_to login_url, :alert => "First login to access this page."
  end  
end