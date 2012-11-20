class SessionsController < ApplicationController
	skip_before_filter :require_login #, :only => [:new, :create]
	def new
	end

	def create
	  person = login(params[:email], params[:password], params[:remember_me])
	  if person
	    redirect_to root_url, :notice => "Logged in!"
	  else
	    flash[:notice]= "Email or password was invalid"
	    render :new
	  end
	end

	def destroy
	  logout
	  redirect_to root_url, :notice => "Logged out!"
	end
end
