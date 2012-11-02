Reservations::Application.routes.draw do
   
  root :to => 'catalog#index'

  resources :documents, 
            :equipment_objects,
            :requirements

  resources :categories do
    resources :equipment_models
  end

  resources :equipment_models do
    resources :equipment_objects
  end

  match '/users/import' => 'users#import_page', :via => :get, :as => :csv_import_page
  match '/users/import' => 'users#import', :via => :post, :as => :csv_import
  resources :users do
    collection do
      get :find
    end
  end

  match '/catalog/search' => 'catalog#search', :as => :catalog_search
  match '/markdown_help' => 'application#markdown_help', :as => :markdown_help

  resources :reservations do
    member do
      get :checkout_email
      get :checkin_email
      put :renew
    end
    get :autocomplete_user_last_name, :on => :collection
  end
  
  match '/black_outs/flash_message' => 'black_outs#flash_message', :as => :flash_message
  match '/black_outs/new_recurring' => 'black_outs#new_recurring', :as => :new_recurring_black_out

  resources :black_outs do
    member do
      get :flash_message
      delete :destroy_recurring
    end
  end

  # reservations views
  match '/reservations/manage/:user_id' => 'reservations#manage', :as => :manage_reservations_for_user
  match '/reservations/current/:user_id' => 'reservations#current', :as => :current_reservations_for_user
  
  
  # reservation checkout / check-in actions
  match '/reservations/checkout/:user_id' => 'reservations#checkout', :via => :put, :as => :checkout
  match '/reservations/check-in/:user_id' => 'reservations#checkin', :via => :put, :as => :checkin
  
  match '/catalog/update_view' => 'catalog#update_user_per_cat_page', :as => :update_user_per_cat_page
  match '/catalog' => 'catalog#index', :as => :catalog
  match '/add_to_cart/:id' => 'catalog#add_to_cart', :via => :put, :as => :add_to_cart
  match '/remove_from_cart/:id' => 'catalog#remove_from_cart', :via => :put, :as => :remove_from_cart
  match '/cart/empty' => 'application#empty_cart', :via => :delete, :as => :empty_cart
  match '/cart/update' => 'application#update_cart', :as => :update_cart
  
  match '/reports/index' => 'reports#index', :as => :reports
  match '/reports/:id/for_model' => 'reports#for_model', :as => :for_model_report
  match '/reports/for_model_set' => 'reports#for_model_set', :as => :for_model_set_reports
  match '/reports/update' => 'reports#update_dates', :as => :update_dates
  match '/reports/generate' => 'reports#generate', :as => :generate_report
  
  match '/:controller/:id/deactivate' => ':controller#deactivate', :via => :put, :as => 'deactivate'
  match '/:controller/:id/activate' => ':controller#activate', :via => :put, :as => 'activate'

  match '/logout' => 'application#logout', :as => :logout

  match '/terms_of_service' => 'application#terms_of_service', :as => :tos

  # yes, both of these are needed to override rails defaults of /controller/:id/edit
  match '/app_configs/' => 'app_configs#edit', :as => :edit_app_configs
  resources :app_configs, :only => [:update]
  
  match '/new_admin_user' => 'application_setup#new_admin_user', :as => :new_admin_user
  match '/create_admin_user' => 'application_setup#create_admin_user', :as => :create_admin_user
  resources :application_setup, :only => [:new_admin_user, :create_admin_user]
  
  match '/new_app_configs' => 'application_setup#new_app_configs', :as => :new_app_configs
  match '/create_app_configs' => 'application_setup#create_app_configs', :as => :create_app_configs
  
  match 'contact' => 'contact#new', :as => 'contact_us', :via => :get
  match 'contact' => 'contact#create', :as => 'contact_us', :via => :post
  
  match ':controller(/:action(/:id(.:format)))' 

end
