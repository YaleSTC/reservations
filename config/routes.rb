Reservations::Application.routes.draw do

  root :to => 'catalog#index'

  resources :documents
  resources :equipment_objects
  
  resources :equipment_models do
    resources :equipment_objects
  end
  
  resources :categories do
    resources :equipment_models
  end
  
  resources :users do
    collection do
      get :check_out
      get :check_in
    end
    resources :reservations
  end
  
  resources :reservations do
    member do
      get :check_out
      get :check_in
      get :check_out_single
      get :check_in_single
      get :show_all
      get :checkout_email
      get :checkin_email
    end
    get :autocomplete_user_last_name, :on => :collection
  end

  
  match '/reservations/show_all/for_user/:user_id' => 'reservations#show_all', :as => :show_all_reservations_for_user
  match '/reservations/check_out/for_user/:user_id' => 'reservations#check_out', :as => :check_out_reservations_for_user
  match '/reservations/check_in/for_user/:user_id' => 'reservations#check_in', :as => :check_in_reservations_for_user
  
  match '/catalog' => 'catalog#index', :as => :catalog
  match '/catalog/add_to_cart/:id' => 'catalog#add_to_cart', :as => :add_to_cart
  match '/catalog/remove_from_cart/:id' => 'catalog#remove_from_cart', :as => :remove_from_cart
  
  match '/cart/empty' => 'application#empty_cart', :as => :empty_cart
  match '/cart/update' => 'application#update_cart', :as => :update_cart
  
  match '/:controller/:id/deactivate' => ':controller#deactivate', :as => 'deactivate'
  match '/:controller/:id/activate' => ':controller#activate', :as => 'activate'

  match '/logout' => 'application#logout', :as => :logout
  
  match '/app_config/edit' => 'app_config#edit', :as => :edit_app_config
  match '/app_config/update' => 'app_config#update', :as => :update_app_config  
  
  match ':controller(/:action(/:id(.:format)))'

end
