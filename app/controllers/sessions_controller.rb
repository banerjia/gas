class SessionsController < ApplicationController
	skip_before_filter :require_login, :only => [:new, :create]
  
  def new
    @page_title = "Sign In"
  end
  
	def create
	  @page_title = "Sign In"
	  person = login(params[:email], params[:password], params[:remember_me])
	  if person
	    redirect_back_or_to root_url
	  else
	    flash[:warning]= "Please review your credentials and try again."
	    render :new
	  end
	end

	def destroy
	  logout
	  redirect_to root_url, :notice => "You have successfully been signed out."
	end
end
