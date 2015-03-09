require 'spec_helper'

class TestController < ApplicationController
  before_filter :require_admin, only: [:method_requiring_admin]
  before_filter :require_checkout_person,
                only: [:method_requiring_checkout_person]
  before_filter :require_user_or_checkout_person,
                only: [:method_requiring_user_or_checkout_person]
  before_filter :require_user, only: [:method_requiring_user]

  def index
    render text: 'hello world'
  end

  def terms_of_service
    render text: 'terms_of_service'
  end

  def activate
    render text: 'one of two methods requiring the admin before_filter'
  end

  def deactivate
    render text: 'the second of two methods requiring the admin before_filter'
  end

  def method_requiring_admin
    render text: 'admin required!'
  end

  def method_requiring_checkout_person
    render text: 'checkout person required!'
  end

  def method_requiring_user_or_checkout_person
    render text: 'are you a user or a checkout person?'
  end

  def method_requiring_user
    render text: 'you are a user, congrats.'
  end
end

describe TestController, type: :controller do
  before(:each) do
    @app_config = FactoryGirl.create(:app_config)
    # this is to ensure that all before_filters are run
    @first_user = FactoryGirl.create(:user)
    allow(controller).to receive(:app_setup_check)
    allow(controller).to receive(:load_configs)
    allow(controller).to receive(:seen_app_configs)
    allow(controller).to receive(:cart)
    allow(controller).to receive(:fix_cart_date)
    allow(controller).to receive(:set_view_mode)
    allow(controller).to receive(:make_cart_compatible)
    @user = FactoryGirl.create(:user)
    sign_in @user
  end

  describe 'make_cart_compatible' do
    before(:each) do
      allow(controller).to receive(:make_cart_compatible).and_call_original
    end
    it 'replaces the cart if items is an Array' do
      session[:cart] = FactoryGirl.build(:cart, items: [1])
      get :index
      expect(session[:cart].items).to be_a(Hash)
      expect(session[:cart].items).to be_empty
      expect(session[:cart].items).not_to be_a(Array)
    end
    it 'leaves the cart alone if items is a Hash' do
      session[:cart] = FactoryGirl.build(:cart_with_items)
      expect { get :index }.to_not change { session[:cart].items }
    end
  end

  describe 'app_setup_check' do
    before(:each) do
      allow(controller).to receive(:app_setup_check).and_call_original
    end
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
      allow(controller).to receive(:load_configs).and_return(@app_config)
      allow(controller).to receive(:seen_app_configs).and_call_original
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
      allow(controller).to receive(:load_configs).and_call_original
      get :index
      expect(assigns(:app_configs)).to eq(AppConfig.first)
    end
  end

  describe 'cart' do
    before(:each) do
      allow(controller).to receive(:cart).and_call_original
    end
    it 'makes a new cart record for session[:cart] if !cart' do
      get :index
      expect(session[:cart]).to be_new_record
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

  describe 'set_view_mode' do
    # this has changed as of the resolution of #415
  end

  describe 'fix_cart_date' do
    before(:each) do
      allow(controller).to receive(:fix_cart_date).and_call_original
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

describe ApplicationController, type: :controller do
  before(:each) do
    @app_config = FactoryGirl.create(:app_config)
    # this is to ensure that all before_filters are run
    @first_user = FactoryGirl.create(:user)
    allow(controller).to receive(:app_setup_check)
    allow(controller).to receive(:load_configs)
    allow(controller).to receive(:seen_app_configs)
    allow(controller).to receive(:cart)
    allow(controller).to receive(:fix_cart_date)
    allow(controller).to receive(:set_view_mode)
    allow(controller).to receive(:make_cart_compatible)
    sign_in FactoryGirl.create(:user)
  end

  # TODO: This may involve rewriting the method somewhat
  describe 'PUT update_cart' do
    before(:each) do
      session[:cart] = Cart.new
      session[:cart].reserver_id = @first_user.id
      session[:cart].start_date = (Time.zone.today + 1.day)
      session[:cart].due_date = (Time.zone.today + 2.days)

      equipment_model =
        FactoryGirl.create(:equipment_model,
                           category: FactoryGirl.create(:category))
      FactoryGirl.create(:equipment_item,
                         equipment_model_id: equipment_model.id)
      session[:cart].add_item(equipment_model)
      @new_reserver = FactoryGirl.create(:user)
    end

    context 'valid parameters' do
      it 'should update cart dates' do
        new_start = Time.zone.today + 3.days
        new_end = Time.zone.today + 4.days

        put :update_cart, cart: { start_date_cart: new_start,
                                  due_date_cart: new_end },
                          reserver_id: @new_reserver.id

        expect(session[:cart].start_date).to eq(new_start)
        expect(session[:cart].due_date).to eq(new_end)
        expect(session[:cart].reserver_id).to eq(@new_reserver.id.to_s)
      end

      it 'should not set the flash' do
        expect(flash).to be_empty
      end
    end

    context 'invalid parameters' do
      it 'should set the flash' do
        new_start = Time.zone.today - 300.days
        new_end = Time.zone.today + 4000.days

        put :update_cart,
            cart: { start_date_cart: new_start.strftime('%m/%d/%Y'),
                    due_date_cart: new_end.strftime('%m/%d/%Y') },
            reserver_id: @new_reserver.id

        expect(flash).not_to be_empty
      end
    end

    context 'banned reserver' do
      it 'should set the flash' do
        put :update_cart,
            cart: { start_date_cart: Time.zone.today,
                    due_date_cart: Time.zone.today + 1.day },
            reserver_id: FactoryGirl.create(:banned).id
        expect(flash[:error].strip).not_to eq('')
      end
    end
  end

  describe 'DELETE empty_cart' do
    before(:each) do
      session[:cart] = Cart.new
      session[:cart].reserver_id = @first_user.id
      delete :empty_cart
    end
    it 'empties the cart' do
      expect(session[:cart].items).to be_empty
    end
    it { is_expected.to redirect_to(root_path) }
    it { is_expected.to set_flash }
  end

  describe 'GET terms_of_service' do
    before(:each) do
      @app_config = FactoryGirl.create(:app_config)
      controller.instance_variable_set(:@app_configs, @app_config)
      get :terms_of_service
    end
    it { is_expected.to render_template('terms_of_service/index') }
    it 'assigns @app_config.terms_of_service to @tos' do
      expect(assigns(:tos)).to eq(@app_config.terms_of_service)
    end
  end

  describe 'PUT deactivate' do
    it 'should assign @objects_class2 to the object and controller '\
      'specified by params'
    it 'should delete @objects_class2'
    it 'should set the flash'
    it 'should redirect to request.referer'
  end

  describe 'PUT activate' do
    it 'should assign @model_to_activate to the model to be activated'
    it 'should call activatParents on the assigned model'
    it 'should revive @model_to_activate'
    it 'should set the flash'
    it 'should redirect to request.referer'
  end

  describe 'GET markdown_help' do
    before(:each) do
      get :markdown_help
    end
    it { is_expected.to render_template('shared/_markdown_help') }
    # TODO: not sure how to make sure that the js template is being rendered
    # as well.
  end
end
