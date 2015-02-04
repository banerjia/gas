Graeters::Application.routes.draw do
  defaults( format: :html ) do 

    root to: 'home#index', format: :html	  
    namespace :api, constraints: { format: :json } do
      namespace :v1 do
        resources :regions, only: [:index]

        get 's3/access_token/:bucket' => 's3#access_token', as: "s3_access_token"

        get 'stores/search' => 'stores#search', as: "stores_search"
        get 'audits/search' => 'audits#search', as: "audit_search"
      end
    end
    constraints( id: /\d+/) do

      get "stores/search" => 'stores#search', as: "stores_search"
      resources :stores do
        get "audits" => "audits#search", as: "audits"
        get "orders/new" => "orders#new", as: "new_order"
        get "audits/new" => "audits#new", as: "new_audit"
      end	

      resources :companies do
        get "states" => "companies#company_states", as: "states", format: :json
        get "stores/:country-:state" => "stores#search", constraints: {state: /[a-zA-Z]{2,}/,country: /[a-zA-Z]{2}/}, as: "stores_by_state"	     
        get "stores" => "stores#search", as: "stores"
				get "stores/new" => "stores#new", as: "new_store"          
      end      
      
      
      
      get "signout" => "sessions#destroy", as: "logout"
      get "signin" => "sessions#new", as: "login"

      
      resources :audits
      resources :resources, only: ["index"]

      resources :product_categories do 
        match "products" => "products#products_by_category", as: "products", via: [:get, :post]
      end

      resources :products
      resources :people
      resources :sessions


    end
    post "order/email" => "orders#send_email", as: "email_order"
    get "orders/search" => "orders#search", as: "orders_search"
    get 'audits/search' => 'audits#search', as: 'audit_search'
    resources :orders
  end
end
