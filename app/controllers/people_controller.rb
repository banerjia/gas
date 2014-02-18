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
  
  private
  
  def person_params
    params.require(:person).permit(:name, :email, :crypted_password, :salt, :is_admin, :remember_me_token, :remember_me_token_expires_at)
  end
end
