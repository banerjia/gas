Graeters::Application.routes.draw do
	defaults( :format => :html ) do 
	  
	  root :to => 'companies#index', :format => :html	  
	  constraints( :id => /\d+/) do
	  
		match "stores/search" => 'stores#search', :as => "stores_search"
		resources :stores do
			match "audits" => "audits#search", :as => "audits"
			#match "audits/new" => "audits#new", :as => "new_audit", :via => :get, :format => :html
		end	
		
		resources :companies do
			match "states" => "companies#company_states", :as => "states", :format => :json
			match "stores/:country-:state" => "stores#search", :constraints => {:state => /[a-zA-Z]{2,}/,:country => /[a-zA-Z]{2}/}, :as => "stores_by_state"	     
			match "stores" => "stores#search", :as => "stores"
			
		end
		
		resources :audits   
		
	  end

	  
	  # root :to => 'companies#index'
	  # The priority is based upon order of creation:
	  # first created -> highest priority.

	  # Sample of regular route:
	  #   match 'products/:id' => 'catalog#view'
	  # Keep in mind you can assign values other than :controller and :action

	  # Sample of named route:
	  #   match 'products/:id/purchase' => 'catalog#purchase', :as => :purchase
	  # This route can be invoked with purchase_url(:id => product.id)

	  # Sample resource route (maps HTTP verbs to controller actions automatically):
	  #   resources :products

	  # Sample resource route with options:
	  #   resources :products do
	  #     member do
	  #       get 'short'
	  #       post 'toggle'
	  #     end
	  #
	  #     collection do
	  #       get 'sold'
	  #     end
	  #   end

	  # Sample resource route with sub-resources:
	  #   resources :products do
	  #     resources :comments, :sales
	  #     resource :seller
	  #   end

	  # Sample resource route with more complex sub-resources
	  #   resources :products do
	  #     resources :comments
	  #     resources :sales do
	  #       get 'recent', :on => :collection
	  #     end
	  #   end

	  # Sample resource route within a namespace:
	  #   namespace :admin do
	  #     # Directs /admin/products/* to Admin::ProductsController
	  #     # (app/controllers/admin/products_controller.rb)
	  #     resources :products
	  #   end

	  # You can have the root of your site routed with "root"
	  # just remember to delete public/index.html.
	  # root :to => 'welcome#index'

	  # See how all your routes lay out with "rake routes"

	  # This is a legacy wild controller route that's not recommended for RESTful applications.
	  # Note: This route will make all actions in every controller accessible via GET requests.
	  # match ':controller(/:action(/:id(.:format)))'
	end
end
