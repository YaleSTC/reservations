Reservations::Application.routes.draw do

  map.resources :reservations, :member => {:check_out => :get, :check_in => :get, :check_out_single => :get, :check_in_single => :get, :show_all => :get}
  map.show_all_reservations_for_user '/reservations/show_all/for_user/:user_id', :controller => 'reservations', :action => 'show_all'
  map.check_out_reservations_for_user '/reservations/check_out/for_user/:user_id', :controller => 'reservations', :action => 'check_out'
  map.check_in_reservations_for_user '/reservations/check_in/for_user/:user_id', :controller => 'reservations', :action => 'check_in'

  map.resources :documents
  map.resources :equipment_objects
  map.resources :equipment_models do |equipment_model|
    equipment_model.resources :equipment_objects
  end
  map.resources :categories do |category|
    category.resources :equipment_models
  end
  map.resources :users, :collection => {:check_out => :get, :check_in => :get} do |user|
    user.resources :reservations
  end

  map.catalog '/catalog', :controller => 'catalog'
  map.add_to_cart '/catalog/add_to_cart/:id', :controller => 'catalog', :action => 'add_to_cart'
  map.remove_from_cart '/catalog/remove_from_cart/:id', :controller => 'catalog', :action => 'remove_from_cart'
  map.empty_cart '/cart/empty', :controller => 'application', :action => 'empty_cart'
  map.update_cart '/cart/update', :controller => 'application', :action => 'update_cart'
  map.logout '/logout', :controller => 'application', :action => 'logout'
  map.edit_app_config '/app_config/edit', :controller => 'app_config', :action => 'edit'
  map.update_app_config '/app_config/update', :controller => 'app_config', :action => 'update'

  map.root :controller => "catalog"

  map.connect ':controller/:action/:id'
  map.connect ':controller/:action/:id.:format'

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
  # root :to => "welcome#index"

  # See how all your routes lay out with "rake routes"

  # This is a legacy wild controller route that's not recommended for RESTful applications.
  # Note: This route will make all actions in every controller accessible via GET requests.
  # match ':controller(/:action(/:id(.:format)))'
end
