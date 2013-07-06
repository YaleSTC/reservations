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

  get '/import_users/import' => 'import_users#import_page', :via => :get, :as => :csv_import_page
  post '/import_users/imported' => 'import_users#import', :via => :post, :as => :csv_imported

  resources :users do
    collection do
      get :find
    end
  end

  match '/catalog/search' => 'catalog#search', :as => :catalog_search # what kind of http request is this?
  get '/markdown_help' => 'application#markdown_help', :as => :markdown_help

  resources :reservations do
    member do
      get :checkout_email
      get :checkin_email
      put :renew
    end
    get :autocomplete_user_last_name, :on => :collection
  end

  get '/blackouts/flash_message' => 'blackouts#flash_message', :as => :flash_message
  get '/blackouts/new_recurring' => 'blackouts#new_recurring', :as => :new_recurring_blackout

  resources :blackouts do
    collection do
      post :create_recurring
    end
    member do
      get :flash_message
      delete :destroy_recurring
    end
  end

  # reservations views
  get '/reservations/manage/:user_id' => 'reservations#manage', :as => :manage_reservations_for_user
  get '/reservations/current/:user_id' => 'reservations#current', :as => :current_reservations_for_user


  # reservation checkout / check-in actions
  put '/reservations/checkout/:user_id' => 'reservations#checkout', :via => :put, :as => :checkout
  put '/reservations/check-in/:user_id' => 'reservations#checkin', :via => :put, :as => :checkin

  put '/catalog/update_view' => 'catalog#update_user_per_cat_page', :as => :update_user_per_cat_page
  get '/catalog' => 'catalog#index', :as => :catalog
  put '/add_to_cart/:id' => 'catalog#add_to_cart', :via => :put, :as => :add_to_cart
  put '/remove_from_cart/:id' => 'catalog#remove_from_cart', :via => :put, :as => :remove_from_cart
  delete '/cart/empty' => 'application#empty_cart', :via => :delete, :as => :empty_cart
  put '/cart/update' => 'application#update_cart', :as => :update_cart

  get '/reports/index' => 'reports#index', :as => :reports
  get '/reports/:id/for_model' => 'reports#for_model', :as => :for_model_report
  match '/reports/for_model_set' => 'reports#for_model_set', :as => :for_model_set_reports
  match '/reports/update' => 'reports#update_dates', :as => :update_dates
  put '/reports/generate' => 'reports#generate', :as => :generate_report

  put '/:controller/:id/deactivate' => ':controller#deactivate', :via => :put, :as => 'deactivate'
  put '/:controller/:id/activate' => ':controller#activate', :via => :put, :as => 'activate'

  match '/logout' => 'application#logout', :as => :logout # what kind of http request is this?

  match '/terms_of_service' => 'application#terms_of_service', :as => :tos # see what this method actually does

  # yes, both of these are needed to override rails defaults of /controller/:id/edit
  get '/app_configs/' => 'app_configs#edit', :as => :edit_app_configs
  resources :app_configs, :only => [:update]

  get '/new_admin_user' => 'application_setup#new_admin_user', :as => :new_admin_user
  post '/create_admin_user' => 'application_setup#create_admin_user', :as => :create_admin_user
  resources :application_setup, :only => [:new_admin_user, :create_admin_user]

  get '/new_app_configs' => 'application_setup#new_app_configs', :as => :new_app_configs
  post '/create_app_configs' => 'application_setup#create_app_configs', :as => :create_app_configs

  get 'contact' => 'contact#new', :as => 'contact_us', :via => :get
  post 'contact' => 'contact#create', :as => 'contact_us', :via => :post

  match ':controller(/:action(/:id(.:format)))'

end
