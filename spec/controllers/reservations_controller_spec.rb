require 'spec_helper'

describe ReservationsController do
  render_views

  before(:all) do
    @app_config = FactoryGirl.create(:app_config)

    @user = FactoryGirl.create(:user)
    @banned = FactoryGirl.create(:banned)
    @checkout_person = FactoryGirl.create(:checkout_person)
    @admin = FactoryGirl.create(:admin)

    @reservation = FactoryGirl.create(:reservation, reserver: @user)
  end

  after(:all) do
    User.delete_all
    AppConfig.delete_all
    Reservation.delete_all
  end

  before(:each) do
    @cart = FactoryGirl.build(:cart, reserver_id: @user.id)

    @controller.stub(:first_time_user).and_return(nil)
    @controller.stub(:current_user).and_return(@user)
  end

  ##### Public methods of ReservationsController with routes

  ## Standard
  # index (GET index / ), show (GET /:id), new (GET /new),
  # create (POST /create), edit (GET /:id/edit), update (PUT /:id),
  # destroy (DELETE /:id)

  ## Custom
  # manage (GET /manage/:user_id), current (GET /current/:user_id)
  # checkout (PUT '/reservations/checkout/:user_id'),
  # checkin (PUT '/reservations/check-in/:user_id'),
  # checkout_email (GET 'reservations/checkout_email'),
  # checkin_email (GET 'reservations/checkin_email'),
  # renew (PUT '/reservations/renew')

  ## ?
  # upcoming, autocomplete_user_last_name

  ##### CanCan authentication summary
  # -> banned users can't do anything
  # -> Patrons can show and new/create/destroy their own reservation
  #    (destroy if it hasn't been checked out), renew own
  #    (if it's checked out and not yet checked in)
  # -> Checkout Persons can:
  #     do everything Patrons can do
  #     read, create... but not destroy Reservation
  #         (unless it hasn't been checked out yet)
  #     update reservation, override reservation errors and checkout errors
  #     if respective AppConfig settings allow it
  # => Admins can:
  #     do everything



  describe '#index GET /reservations/' do
    # check params[:filter]
    # depending on admin status, default_filter changes
    # depending on admin status, source of reservations (all v. own) changes
    context 'when accessed by non-banned user' do
      subject { get :index }
      it { should be_success }
      it { should render_template(:index) }

      it 'populates @reservations_set with reservations with respect to params[filter]'
      it 'passes @default as false if valid params[filter] is provided'
      it 'passes @default as true if params[filter] is not provided'
      it 'passes @default as true if invalid params[filter] is provided'

      context 'who is an admin' do
        before(:each) do
          @controller.stub(:current_user).and_return(@admin)
        end
        it 'uses :upcoming as default filter'
        it 'takes all Reservations as source'
      end

      context 'who is not an admin' do
        before(:each) do
          @controller.stub(:current_user).and_return(@user)
        end
        it 'uses :reserved as the default filter'
        it 'uses only reservations belonging to current user as source'
      end
    end

    context 'when accessed by a banned user' do
      before(:each) do
        @controller.stub(:current_user).and_return(@banned)
        get :index
      end
      it { should set_the_flash }
      it { response.should be_redirect }
    end
  end

  describe '#show GET /reservations/:id' do
    context 'when accessed by a non-banned user' do=
      context 'who is an admin' do
        it 'should display own reservation'
        it 'should display anybody\'s reservation'
      end

      context 'who is not an admin' do
        it 'should display own reservation'
        it 'should not display someone else\'s reservation'
      end
    end

    context 'when accessed by a banned user' do
      before(:each) do
        @controller.stub(:current_user).and_return(@banned)
        Reservation.stub(:find).and_return(@reservation)
        get :show, id: 1
      end
      it { should set_the_flash }
      it { response.should be_redirect }
    end
  end

  describe '#new GET /reservations/new' do
  end

  describe '#create POST /reservations/create' do
  end

  describe '#edit GET /reservations/:id/edit' do
  end

  describe '#update PUT /reservations/:id' do
  end

  describe '#destroy DELETE /reservations/:id' do
  end

  describe '#manage GET /reservations/manage/:user_id' do
  end

  describe '#current GET /reservations/current/:user_id' do
  end
end