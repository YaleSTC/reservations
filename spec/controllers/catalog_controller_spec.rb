# frozen_string_literal: true

require 'spec_helper'

describe CatalogController, type: :controller do
  before(:each) do
    @app_config = FactoryGirl.create(:app_config)
    @user = FactoryGirl.create(:user)
    @cart = FactoryGirl.build(:cart, reserver_id: @user.id)
    sign_in @user
    # @controller.stub(:cart).and_return(session[@cart])
    # @controller.stub(:fix_cart_date)
  end
  describe 'GET index' do
    before(:each) do
      # the first hash passed here is params[] and the second is session[]
      get :index, params: {} # , { cart: @cart }
    end
    it 'sets @reserver_id to the current cart.reserver_id' do
      expect(assigns(:reserver_id)).to eq(@user.id)
    end
    it { is_expected.to respond_with(:success) }
    it { is_expected.to render_template(:index) }
    it { is_expected.not_to set_flash }
  end
  describe 'PUT add_to_cart' do
    context 'valid equipment_model selected' do
      before(:each) do
        @equipment_model = FactoryGirl.create(:equipment_model)
        put :add_to_cart, params: { id: @equipment_model.id }
      end
      it 'should call cart.add_item to add item to cart' do
        expect do
          put :add_to_cart, params: { id: @equipment_model.id }
        end.to change { session[:cart].items[@equipment_model.id] }.by(1)
      end
      it 'should set flash[:error] if errors exist' do
        allow(@cart).to receive(:validate_items).and_return('test')
        allow(@cart).to receive(:validate_dates_and_items).and_return('test2')
        expect(flash[:error]).not_to be_nil
      end
      it { is_expected.to redirect_to(root_path) }
    end
    context 'invalid equipment_model selected' do
      before(:each) do
        # there are no equipment models in the db so this is invalid
        put :add_to_cart, params: { id: 1 }
      end
      it { is_expected.to redirect_to(root_path) }
      it { is_expected.to set_flash }
      it 'should add logger error' do
        expect(Rails.logger).to\
          receive(:error).with('Attempt to add invalid equipment model 1')
        # this call has to come after the previous line
        put :add_to_cart, params: { id: 1 }
      end
    end
  end

  describe 'POST submit_cart_updates_form on item' do
    before(:each) do
      @equipment_model = FactoryGirl.create(:equipment_model)
      put :add_to_cart, params: { id: @equipment_model.id }
    end
    it 'should adjust item quantity' do
      params = { id: @equipment_model.id,
                 quantity: 2,
                 reserver_id: @user.id }
      post :submit_cart_updates_form, params: params
      expect(session[:cart].items[@equipment_model.id]).to eq(2)
      expect(assigns(:errors)).to eq session[:cart].validate_all
      is_expected.to redirect_to(new_reservation_path)
    end
    it 'should remove item when quantity is 0' do
      params = { id: @equipment_model.id,
                 quantity: 0,
                 reserver_id: @user.id }
      post :submit_cart_updates_form, params: params
      # should remove the item after setting quantity to 0
      expect(session[:cart].items).to be_empty
      is_expected.to redirect_to(root_path)
    end
  end

  describe 'PUT changing dates on confirm reservation page' do
    before(:each) do
      @equipment_model = FactoryGirl.create(:equipment_model)
      put :add_to_cart, params: { id: @equipment_model.id }
    end
    it 'should set new dates' do
      # sets start and due dates to tomorrow and day after tomorrow
      tomorrow = Time.zone.today + 1.day
      params = { cart: { start_date_cart: tomorrow.strftime('%Y-%m-%d'),
                         due_date_cart:
                         (tomorrow + 1.day).strftime('%Y-%m-%d') },
                 reserver_id: @user.id }
      post :change_reservation_dates, params: params
      expect(session[:cart].start_date).to eq(tomorrow)
      expect(session[:cart].due_date).to eq(tomorrow + 1.day)
    end
  end

  describe 'PUT update_user_per_cat_page' do
    before(:each) do
      put :update_user_per_cat_page
    end
    it 'should set session[:items_per_page] to params[items_per_page] '\
      'if exists' do
      put :update_user_per_cat_page, params: { items_per_page: 20 }
      expect(session[:items_per_page]).to eq('20')
    end
    it 'should not alter session[:items_per_page] if '\
      'params[:items_per_page] is nil' do
      session[:items_per_page] = '15'
      put :update_user_per_cat_page, params: { items_per_page: nil }
      expect(session[:items_per_page]).not_to eq(nil)
      expect(session[:items_per_page]).to eq('15')
    end
    it { is_expected.to redirect_to(root_path) }
  end

  # I don't like that this test is actually searching the database, but
  # unfortunately I couldn't get the model methods to stub correctly
  describe 'PUT search' do
    context 'query is blank' do
      before(:each) do
        put :search, params: { query: '' }
      end
      it { is_expected.to redirect_to(root_path) }
    end
    context 'query is not blank' do
      it 'should call catalog_search on EquipmentModel and return active '\
        'equipment models' do
        @equipment_model = FactoryGirl.create(:equipment_model,
                                              active: true,
                                              description: 'query')
        # EquipmentModel.stub(:catelog_search).with('query')
        #   .and_return(@equipment_model)
        put :search, params: { query: 'query' }
        expect(assigns(:equipment_model_results)).to eq([@equipment_model])
      end
      it 'should give unique results even with multiple matches' do
        @equipment_model = FactoryGirl.create(:equipment_model,
                                              active: true,
                                              name: 'query',
                                              description: 'query')
        put :search, params: { query: 'query' }
        expect(assigns(:equipment_model_results)).to eq([@equipment_model])
        expect(assigns(:equipment_model_results).uniq!).to eq(nil) # no dups
      end
      it 'should call catalog_search on EquipmentItem' do
        @equipment_item =
          FactoryGirl.create(:equipment_item, serial: 'query')
        # EquipmentItem.stub(:catelog_search).with('query')
        #   .and_return(@equipment_item)
        put :search, params: { query: 'query' }
        expect(assigns(:equipment_item_results)).to eq([@equipment_item])
      end
      it 'should call catalog_search on Category' do
        @category = FactoryGirl.create(:category, name: 'query')
        # Category.stub(:catelog_search).with('query').and_return(@category)
        put :search, params: { query: 'query' }
        expect(assigns(:category_results)).to eq([@category])
      end
    end
  end

  context 'application-controller centric tests' do
    before(:each) do
      @app_config = FactoryGirl.create(:app_config)
      # this is to ensure that all before_filters are run
      @first_user = FactoryGirl.create(:user)
      @user = FactoryGirl.create(:user)
      sign_in @user
    end

    describe 'app_setup_check' do
      context 'user and appconfig in the db' do
        before(:each) do
          get :index
        end
        it { is_expected.to respond_with(:success) }
        it { is_expected.not_to set_flash }
      end
      context 'no app_config' do
        before(:each) do
          AppConfig.delete_all
          get :index
        end
        it { is_expected.to set_flash }
        it { is_expected.to render_template('application_setup/index') }
      end
      context 'no user in the db' do
        before(:each) do
          sign_out @user
          User.delete_all
          get :index
        end
        it { is_expected.to set_flash }
        it { is_expected.to render_template('application_setup/index') }
      end
    end

    describe 'seen_app_configs' do
      before(:each) do
        @admin = FactoryGirl.create(:admin)
        sign_in @admin
      end
      context 'app configs have not been viewed' do
        before(:each) do
          AppConfig.delete_all
          @app_config = FactoryGirl.create(:app_config, viewed: false)
          get :index
        end
        it { is_expected.to set_flash }
        it { is_expected.to respond_with(:redirect) }
        it { is_expected.to redirect_to(edit_app_configs_path) }
      end
      context 'app configs have been viewed' do
        before(:each) do
          get :index
        end
        it { is_expected.not_to set_flash }
        it { is_expected.to respond_with(:success) }
        it { is_expected.not_to redirect_to(edit_app_configs_path) }
      end
    end

    describe 'load_configs' do
      it 'should set @app_configs to the first AppConfig' do
        get :index
        expect(assigns(:app_configs)).to eq(AppConfig.first)
      end
    end

    describe 'cart' do
      it 'makes a new cart record for session[:cart] if !cart' do
        get :index
        expect(session[:cart].is_a?(Cart)).to be_truthy
      end
      it 'returns session[:cart] if cart.reserver_id' do
        session[:cart] = Cart.new
        session[:cart].reserver_id = @user.id
        get :index
        expect(session[:cart].reserver_id).to eq(@user.id)
      end
      it 'sets the session[:cart].reserver_id to current_user.id if '\
        '!cart.reserver_id && current_user' do
        session[:cart] = Cart.new
        get :index
        expect(session[:cart].reserver_id).to eq(@user.id)
      end
      it 'returns session[:cart] without a reserver_id if !cart.reserver_id '\
        '&& !current_user' do
        sign_out @user
        session[:cart] = Cart.new
        get :index
        expect(session[:cart].reserver_id).to be_nil
      end
    end

    describe 'fix_cart_date' do
      before(:each) do
        session[:cart] = Cart.new
        allow(controller).to receive(:cart).and_return(session[:cart])
      end
      it 'changes cart.start_date to today if date is in the past' do
        session[:cart].start_date = Time.zone.today - 1.day
        get :index
        expect(session[:cart].start_date).to eq(Time.zone.today)
      end
      it 'does not change the start_date if date is in the future' do
        session[:cart].start_date = Time.zone.today + 1.day
        get :index
        expect(session[:cart].start_date).to eq(Time.zone.today + 1.day)
        expect(session[:cart].start_date).not_to eq(Time.zone.today)
      end
    end
  end
end
