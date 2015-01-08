Reservations::Application.routes.draw do
  # routes for Devise
  devise_scope :user do
    devise_for :users
  end

  root to: 'catalog#index'

  mount RailsAdmin::Engine => '/admin', as: 'rails_admin'

  get 'status/index'

  concern :deactivatable do
    member do
      put :deactivate
      put :activate
    end
  end

  resources :documents,
            :requirements

  resources :equipment_objects, concerns: :deactivatable

  resources :announcements, except: [:show]

  resources :categories, concerns: :deactivatable do
    resources :equipment_models
  end

  resources :equipment_models, concerns: :deactivatable do
    collection do
      put 'update_cart'
      delete 'empty_cart'
    end
    resources :equipment_objects
  end

  get '/import_users/import' => 'import_users#import_page',
      :as => :csv_import_page
  post '/import_users/imported' => 'import_users#import',
       :as => :csv_imported

  get '/import_equipment/import' => 'import_equipment#import_page',
      :as => :equip_import_page
  post '/import_equipment/imported' => 'import_equipment#import',
       :as => :equip_imported

  resources :users do
    collection do
      post :find
      post :quick_new
      post :quick_create
    end
    member do
      put :ban
      put :unban
    end
    get :autocomplete_user_last_name, on: :collection
  end

  get '/catalog/search' => 'catalog#search',
      :as => :catalog_search # what kind of http request is this?
  get '/markdown_help' => 'application#markdown_help', :as => :markdown_help

  resources :reservations do
    member do
      get :checkout_email
      get :checkin_email
      put :renew
      put :archive
    end
  end

  # reservations views
  get '/reservations/manage/:user_id' => 'reservations#manage',
      :as => :manage_reservations_for_user
  get '/reservations/current/:user_id' => 'reservations#current',
      :as => :current_reservations_for_user

  get '/reservations/review/:id' => 'reservations#review',
      :as => :review_request
  put '/reservations/approve/:id' => 'reservations#approve_request',
      :as => :approve_request
  put '/reservations/deny/:id' => 'reservations#deny_request',
      :as => :deny_request

  # reservation checkout / check-in actions
  put '/reservations/checkout/:user_id' => 'reservations#checkout',
      :as => :checkout
  put '/reservations/check-in/:user_id' => 'reservations#checkin',
      :as => :checkin
  get '/blackouts/flash_message' => 'blackouts#flash_message',
      :as => :flash_message
  get '/blackouts/new_recurring' => 'blackouts#new_recurring',
      :as => :new_recurring_blackout

  resources :blackouts do
    collection do
      post :create_recurring
    end
    member do
      get :flash_message
      delete :destroy_recurring
    end
  end

  put '/catalog/update_view' => 'catalog#update_user_per_cat_page',
      :as => :update_user_per_cat_page
  get '/catalog' => 'catalog#index', :as => :catalog
  put '/add_to_cart/:id' => 'catalog#add_to_cart', :as => :add_to_cart
  put '/remove_from_cart/:id' => 'catalog#remove_from_cart',
      :as => :remove_from_cart
  # delete '/cart/empty' => 'application#empty_cart', :as => :empty_cart
  # put '/cart/update' => 'application#update_cart', :as => :update_cart

  get '/reports/index' => 'reports#index', :as => :reports
  get '/reports/:id/for_model' => 'reports#for_model', :as => :for_model_report

  get '/reports/for_model_set' => 'reports#for_model_set',
      :as => :for_model_set_reports # what http request? old match
  post '/reports/update' => 'reports#update_dates',
       :as => :update_dates # what http request? old match
  post '/reports/generate' => 'reports#generate', :as => :generate_report

  get '/terms_of_service' => 'application#terms_of_service',
      :as => :tos

  # yes, both of these are needed to override rails defaults of
  # /controller/:id/edit
  get '/app_configs/' => 'app_configs#edit', :as => :edit_app_configs # match
  resources :app_configs, only: [:update]

  get '/new_admin_user' => 'application_setup#new_admin_user',
      :as => :new_admin_user
  post '/create_admin_user' => 'application_setup#create_admin_user',
       :as => :create_admin_user
  resources :application_setup, only: [:new_admin_user, :create_admin_user]

  get '/new_app_configs' => 'application_setup#new_app_configs',
      :as => :new_app_configs
  post '/create_app_configs' => 'application_setup#create_app_configs',
       :as => :create_app_configs

  get 'contact' => 'contact#new', :as => 'contact_us'
  post 'contact' => 'contact#create', :as => 'contact_submitted'

  get 'announcements/:id/hide',
      to: 'announcements#hide',
      as: 'hide_announcement'

  get 'status' => 'status#index'

  # generalized matcher
  match ':controller(/:action(/:id(.:format)))', via: [:get, :post, :put,
                                                       :delete]

  # this is a fix for running letter opener inside vagrant
  mount LetterOpenerWeb::Engine, at: '/letter_opener' if Rails.env.development?
end
