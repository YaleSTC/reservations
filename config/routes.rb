Reservations::Application.routes.draw do
  root :to => 'catalog#index'

  ActiveAdmin.routes(self) unless Rails.env.development?

  get "log/index"
  get "log/version/:id" => "log#version", as: :version_view
  get "log/history/:object_type/:id" => "log#history", as: :history

  get "status/index"

  resources :documents,
            :equipment_objects,
            :requirements

  resources :announcements, except: [:show]

  resources :categories do
    resources :equipment_models
  end

  resources :equipment_models do
    resources :equipment_objects
  end

  get '/import_users/import' => 'import_users#import_page', :as => :csv_import_page
  post '/import_users/imported' => 'import_users#import', :as => :csv_imported

  resources :users do
    collection do
      get :find
    end
    get :autocomplete_user_last_name, on: :collection
  end

  get '/catalog/search' => 'catalog#search', :as => :catalog_search # what kind of http request is this?
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

  get '/reservations/review/:id' => 'reservations#review', :as => :review_request
  put '/reservations/approve/:id' => 'reservations#approve_request', :as => :approve_request
  put '/reservations/deny/:id' => 'reservations#deny_request', :as => :deny_request

  # reservation checkout / check-in actions
  put '/reservations/checkout/:user_id' => 'reservations#checkout', :as => :checkout
  put '/reservations/check-in/:user_id' => 'reservations#checkin', :as => :checkin

  put '/catalog/update_view' => 'catalog#update_user_per_cat_page', :as => :update_user_per_cat_page
  get '/catalog' => 'catalog#index', :as => :catalog
  put '/add_to_cart/:id' => 'catalog#add_to_cart', :as => :add_to_cart
  put '/remove_from_cart/:id' => 'catalog#remove_from_cart', :as => :remove_from_cart
  delete '/cart/empty' => 'application#empty_cart', :as => :empty_cart
  put '/cart/update' => 'application#update_cart', :as => :update_cart

  get '/reports/index' => 'reports#index', :as => :reports
  get '/reports/:id/for_model' => 'reports#for_model', :as => :for_model_report
  match '/reports/for_model_set' => 'reports#for_model_set', :as => :for_model_set_reports # what http request?
  match '/reports/update' => 'reports#update_dates', :as => :update_dates # what http request?
  match '/reports/generate' => 'reports#generate', :as => :generate_report # what http request?

  put '/:controller/:id/deactivate' => ':controller#deactivate', :as => 'deactivate'
  put '/:controller/:id/activate' => ':controller#activate', :as => 'activate'

  match '/logout' => 'application#logout', :as => :logout # what kind of http request is this?

  match '/terms_of_service' => 'application#terms_of_service', :as => :tos # change match to get?

  # yes, both of these are needed to override rails defaults of /controller/:id/edit
  match '/app_configs/' => 'app_configs#edit', :as => :edit_app_configs
  resources :app_configs, :only => [:update]

  get '/new_admin_user' => 'application_setup#new_admin_user', :as => :new_admin_user
  post '/create_admin_user' => 'application_setup#create_admin_user', :as => :create_admin_user
  resources :application_setup, :only => [:new_admin_user, :create_admin_user]

  get '/new_app_configs' => 'application_setup#new_app_configs', :as => :new_app_configs
  post '/create_app_configs' => 'application_setup#create_app_configs', :as => :create_app_configs

  get 'contact' => 'contact#new', :as => 'contact_us'
  post 'contact' => 'contact#create', :as => 'contact_us'

  match 'announcements/:id/hide', to: 'announcements#hide', as: 'hide_announcement'

  get 'status' => 'status#index'

  match ':controller(/:action(/:id(.:format)))'

  # this is a fix for running letter opener inside vagrant
  if Rails.env.development?
    mount LetterOpenerWeb::Engine, at: "/letter_opener"
  end

end
