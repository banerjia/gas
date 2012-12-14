Graeters::Application.routes.draw do
  defaults( :format => :html ) do 

    root :to => 'companies#index', :format => :html	  
    constraints( :id => /\d+/) do

      match "stores/search" => 'stores#search', :as => "stores_search"
      resources :stores do
        match "audits" => "audits#search", :as => "audits"
        match "orders/new" => "orders#new", :as => "new_order"
        #match "audits/new" => "audits#new", :as => "new_audit", :via => :get, :format => :html
      end	

      resources :companies do
        match "states" => "companies#company_states", :as => "states", :format => :json
        match "stores/:country-:state" => "stores#search", :constraints => {:state => /[a-zA-Z]{2,}/,:country => /[a-zA-Z]{2}/}, :as => "stores_by_state"	     
        match "stores" => "stores#search", :as => "stores"
      end      
      
      get "signout" => "sessions#destroy", :as => "logout"
      get "signin" => "sessions#new", :as => "login"
      get 'orders' => 'orders#dashboard', :as => "orders_dashboard"

      resources :audits
      resources :resources, :only => ["index"]
      resources :products
      resources :people
      resources :sessions


    end
    post "order/email" => "orders#send_email", :as => "email_order"
    resources :orders
  end
end
