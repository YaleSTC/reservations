require 'spec_helper'

describe ReservationsController do
  before(:all) do
    @app_config = FactoryGirl.create(:app_config)
    @user = FactoryGirl.create(:user)
    @cart = FactoryGirl.build(:cart, reserver_id: @user.id)
    @controller.stub(:current_user).and_return(@user)
    @controller.stub(:first_time_user).and_return(nil)
  end

  ##### From routes.rb
  # # Reservation views
  # get '/reservations/manage/:user_id' => 'reservations#manage', :as => :manage_reservations_for_user
  # get '/reservations/current/:user_id' => 'reservations#current', :as => :current_reservations_for_user
  #
  #
  # # Reservation checkout / check-in actions
  # put '/reservations/checkout/:user_id' => 'reservations#checkout', :as => :checkout
  # put '/reservations/check-in/:user_id' => 'reservations#checkin', :as => :checkin
  #
  # # General Reservation resource routes
  # resources :reservations do
  #   member do
  #     get :checkout_email
  #     get :checkin_email
  #     put :renew
  #   end
  #   get :autocomplete_user_last_name, :on => :collection
  # end

  ##### Public methods of ReservationsController
  # index (GET index / ), show (GET /:id), new (GET /new), create (POST /create), edit (GET /:id/edit), update (PUT /:id)
  # checkout, checkin, destroy, upcoming, manage (GET /manage/:user_id), current (GET /current/:user_id), checkout_email, checkin_email, renew

  describe 'GET /reservations/manage/:user_id' do
  end

  describe 'GET /reservations/current/:user_id' do
  end
end