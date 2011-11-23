class ApplicationController < ActionController::Base
  protect_from_forgery
  $store_inclusions = {:last_audit => {:only => [:id, :score, :created_at,:auditor_name]},
                        :pending_audit => {:only => [:id, :score, :created_at,:auditor_name]}}
  $exclusions = [:created_at, :updated_at]
end
