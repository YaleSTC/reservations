ActionController::Routing::Routes.draw do |map|
  map.resources :reservations, :member => {:check_out => :get, :check_in => :get}
  map.resources :documents
  map.resources :equipment_objects
  map.resources :equipment_models do |equipment_model|
    equipment_model.resources :equipment_objects
  end
  map.resources :categories do |category|
    category.resources :equipment_models
  end
  map.resources :users
  
  map.catalog '/catalog', :controller => 'catalog'
  map.add_to_cart '/catalog/add_to_cart/:id', :controller => 'catalog', :action => 'add_to_cart'
  map.remove_from_cart '/catalog/remove_from_cart/:id', :controller => 'catalog', :action => 'remove_from_cart'
  map.empty_cart '/cart/empty', :controller => 'application', :action => 'empty_cart'
  map.update_cart '/cart/update', :controller => 'application', :action => 'update_cart'
  map.logout '/logout', :controller => 'application', :action => 'logout'

  # The priority is based upon order of creation: first created -> highest priority.

  # Sample of regular route:
  #   map.connect 'products/:id', :controller => 'catalog', :action => 'view'
  # Keep in mind you can assign values other than :controller and :action

  # Sample of named route:
  #   map.purchase 'products/:id/purchase', :controller => 'catalog', :action => 'purchase'
  # This route can be invoked with purchase_url(:id => product.id)

  # Sample resource route (maps HTTP verbs to controller actions automatically):
  #   map.resources :products

  # Sample resource route with options:
  #   map.resources :products, :member => { :short => :get, :toggle => :post }, :collection => { :sold => :get }

  # Sample resource route with sub-resources:
  #   map.resources :products, :has_many => [ :comments, :sales ], :has_one => :seller
  
  # Sample resource route with more complex sub-resources
  #   map.resources :products do |products|
  #     products.resources :comments
  #     products.resources :sales, :collection => { :recent => :get }
  #   end

  # Sample resource route within a namespace:
  #   map.namespace :admin do |admin|
  #     # Directs /admin/products/* to Admin::ProductsController (app/controllers/admin/products_controller.rb)
  #     admin.resources :products
  #   end

  # You can have the root of your site routed with map.root -- just remember to delete public/index.html.
  map.root :controller => "catalog"

  # See how all your routes lay out with "rake routes"

  # Install the default routes as the lowest priority.
  # Note: These default routes make all actions in every controller accessible via GET requests. You should
  # consider removing or commenting them out if you're using named routes and resources.
  map.connect ':controller/:action/:id'
  map.connect ':controller/:action/:id.:format'
end
