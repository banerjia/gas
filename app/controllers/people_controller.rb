class PeopleController < ApplicationController
  def new
	@person = Person.new
  end

  def create
	@person = Person.new( params[:person] )
	if @person.save
		redirect_to root_url :notice => 'New person added to the website'
	else
		render 'new'
	end
  end
end
