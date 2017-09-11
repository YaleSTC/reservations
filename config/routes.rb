# frozen_string_literal: true

Reservations::Application.routes.draw do
  root to: 'catalog#index'

  # routes for Devise
  devise_scope :user do
    devise_for :users
  end

  mount RailsAdmin::Engine => '/admin', as: 'rails_admin'

  ## Concerns
  concern :deactivatable do
    member do
      put :deactivate
      put :activate
    end
  end

  concern :calendarable do
    member { get :calendar }
  end

  resources :documents,
            :requirements

  resources :equipment_items, concerns: %i[deactivatable calendarable]

  resources :announcements, except: [:show]

  resources :categories, concerns: %i[deactivatable calendarable] do
    resources :equipment_models, concern: :calendarable
  end

  resources :equipment_models, concerns: %i[deactivatable calendarable] do
    collection do
      put 'update_catalog_cart'
      delete 'empty_cart'
    end
    resources :equipment_items, concerns: :calendarable
  end

  get 'equipment_objects', to: redirect('equipment_items')
  get 'equipment_objects/:id', to: redirect('equipment_items/%<id>')

  get '/import_users/import', to: 'import_users#import_page',
                              as: :csv_import_page
  post '/import_users/imported', to: 'import_users#import',
                                 as: :csv_imported

  get '/import_equipment/import', to: 'import_equipment#import_page',
                                  as: :equip_import_page
  post '/import_equipment/imported', to: 'import_equipment#import',
                                     as: :equip_imported

  resources :users, concerns: :calendarable do
    collection do
      post :find
      post :quick_new
      post :quick_create
    end
    member do
      put :ban
      put :unban
      delete :empty_cart
    end
    get :autocomplete_user_last_name, on: :collection
  end

  get '/catalog/search', to: 'catalog#search', as: :catalog_search
  get '/markdown_help', to: 'application#markdown_help', as: :markdown_help

  resources :reservations do
    member do
      get :send_receipt
      put :renew
      put :archive
    end
  end

  # reservations views
  get '/reservations/manage/:user_id', to: 'reservations#manage',
                                       as: :manage_reservations_for_user
  get '/reservations/current/:user_id', to: 'reservations#current',
                                        as: :current_reservations_for_user

  get '/reservations/review/:id', to: 'reservations#review',
                                  as: :review_request
  put '/reservations/approve/:id', to: 'reservations#approve_request',
                                   as: :approve_request
  put '/reservations/deny/:id', to: 'reservations#deny_request',
                                as: :deny_request

  # reservation checkout / check-in actions
  put '/reservations/checkout/:user_id', to: 'reservations#checkout',
                                         as: :checkout
  put '/reservations/check-in/:user_id', to: 'reservations#checkin',
                                         as: :checkin
  get '/blackouts/flash_message', to: 'blackouts#flash_message',
                                  as: :flash_message
  get '/blackouts/new_recurring', to: 'blackouts#new_recurring',
                                  as: :new_recurring_blackout

  put '/reservation/update_index_dates', to: 'reservations#update_index_dates',
                                         as: :update_index_dates
  put '/reservation/view_all_dates', to: 'reservations#view_all_dates',
                                     as: :view_all_dates

  resources :blackouts do
    collection do
      post :create_recurring
    end
    member do
      get :flash_message
      delete :destroy_recurring
    end
  end

  put '/catalog/update_view', to: 'catalog#update_user_per_cat_page',
                              as: :update_user_per_cat_page
  get '/catalog', to: 'catalog#index', as: :catalog
  put '/add_to_cart/:id', to: 'catalog#add_to_cart', as: :add_to_cart
  put '/remove_from_cart/:id', to: 'catalog#remove_from_cart',
                               as: :remove_from_cart
  put '/catalog/edit_cart_item/:id', to: 'catalog#edit_cart_item',
                                     as: :edit_cart_item
  post '/catalog/submit_cart_updates_form/:id',
       to: 'catalog#submit_cart_updates_form', as: :submit_cart_updates
  put '/catalog/reload_catalog_cart', to: 'catalog#reload_catalog_cart',
                                      as: :reload_catalog_cart
  put '/catalog/change_reservation_dates',
      to: 'catalog#change_reservation_dates',
      as: :change_reservations_dates
  delete '/catalog/empty_cart', to: 'catalog#empty_cart',
                                as: :catalog_empty_cart

  get '/reports/index', to: 'reports#index', as: :reports
  get '/reports/subreport/:class/:id', to: 'reports#subreport', as: :subreport
  put '/reports/update', to: 'reports#update_dates', as: :update_dates

  get '/terms_of_service', to: 'application#terms_of_service', as: :tos

  # yes, both of these are needed to override rails defaults of
  # /controller/:id/edit
  get '/app_configs/', to: 'app_configs#edit', as: :edit_app_configs # match
  resources :app_configs, only: %i[update] do
    collection do
      put :run_hourly_tasks
      put :run_daily_tasks
    end
  end

  get '/new_admin_user', to: 'application_setup#new_admin_user',
                         as: :new_admin_user
  post '/create_admin_user', to: 'application_setup#create_admin_user',
                             as: :create_admin_user
  resources :application_setup, only: %i[new_admin_user create_admin_user]

  get '/new_app_configs', to: 'application_setup#new_app_configs',
                          as: :new_app_configs
  post '/create_app_configs', to: 'application_setup#create_app_configs',
                              as: :create_app_configs
  put '/reload_catalog_cart', to: 'application#reload_catalog_cart',
                              as: :reload_cart
  delete '/empty_cart', to: 'application#empty_cart', as: :empty_cart

  get 'contact', to: 'contact#new', as: 'contact_us'
  post 'contact', to: 'contact#create', as: 'contact_submitted'

  get 'announcements/:id/hide',
      to: 'announcements#hide',
      as: 'hide_announcement'

  get 'status', to: 'status#index'

  get 'status/index'

  put '/equipment_models/:id/up' => 'equipment_models#up',
      as: 'sort_up'
  put '/equipment_models/:id/down' => 'equipment_models#down',
      as: 'sort_down'

  # this is a fix for running letter opener inside vagrant
  mount LetterOpenerWeb::Engine, at: '/letter_opener' if Rails.env.development?
end
