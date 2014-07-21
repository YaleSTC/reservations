require 'spec_helper'

class TestController < ApplicationController
  before_filter :require_admin, only: [:method_requiring_admin]
  before_filter :require_checkout_person, only: [:method_requiring_checkout_person]
  before_filter :require_login, only: [:method_requiring_login]
  before_filter :require_user_or_checkout_person, only: [:method_requiring_user_or_checkout_person]
  before_filter :require_user, only: [:method_requiring_user]

  def index
    render :text => 'hello world'
  end
  def terms_of_service
    render :text => 'terms_of_service'
  end
  def activate
    render :text => 'one of two methods requiring the admin before_filter'
  end
  def deactivate
    render :text => 'the second of two methods requiring the admin before_filter'
  end
  def method_requiring_admin
    render :text => 'admin required!'
  end
  def method_requiring_checkout_person
    render :text => 'checkout person required!'
  end
  def method_requiring_login
    render :text => 'you must be logged in!'
  end
  def method_requiring_user_or_checkout_person
    render :text => 'are you a user or a checkout person?'
  end
  def method_requiring_user
    render :text => 'you are a user, congrats.'
  end
end

describe TestController do
  before(:each) do
    @app_config = FactoryGirl.create(:app_config)
    @first_user = FactoryGirl.create(:user) # this is to ensure that all before_filters are run
    controller.stub(:app_setup_check)
    controller.stub(:load_configs)
    controller.stub(:seen_app_configs)
    controller.stub(:first_time_user)
    controller.stub(:cart)
    controller.stub(:fix_cart_date)
    controller.stub(:set_view_mode)
    controller.stub(:current_user)
    controller.stub(:make_cart_compatible)
  end

  describe 'make_cart_compatible' do
    before(:each) do
      controller.unstub(:make_cart_compatible)
    end
    it 'replaces the cart if items is an Array' do
      session[:cart] = FactoryGirl.build(:cart, items: [1])
      get :index
      session[:cart].items.should be_a(Hash)
      session[:cart].items.should be_empty
      session[:cart].items.should_not be_a(Array)
    end
    it 'leaves the cart alone if items is a Hash' do
      session[:cart] = FactoryGirl.build(:cart_with_items)
      expect { get :index }.to_not change { session[:cart].items }
    end
  end

  describe 'app_setup_check' do
    before(:each) do
      controller.unstub(:app_setup_check)
    end
    context 'user and appconfig in the db' do
      before(:each) do
        get :index
      end
      it { should respond_with(:success) }
      it { should_not set_the_flash }
    end
    context 'no app_config' do
      before(:each) do
        AppConfig.delete_all
        get :index
      end
      it { should set_the_flash }
      it { should render_template('application_setup/index') }
    end
    context 'no user in the db' do
      before(:each) do
        User.delete_all
        get :index
      end
      it { should set_the_flash }
      it { should render_template('application_setup/index') }
    end
  end

  describe 'seen_app_configs' do
    before(:each) do
      controller.stub(:load_configs).and_return(@app_config)
      controller.unstub(:seen_app_configs)
      @admin = FactoryGirl.create(:admin)
      controller.stub(:current_user).and_return(@admin)
    end
    context 'app configs have not been viewed' do
      before(:each) do
        AppConfig.delete_all
        @app_config = FactoryGirl.create(:app_config, viewed: false)
        get :index
      end
      it { should set_the_flash }
      it { should respond_with(:redirect) }
      it { should redirect_to(edit_app_configs_path) }
    end
    context 'app configs have been viewed' do
      before(:each) do
        get :index
      end
      it { should_not set_the_flash }
      it { should respond_with(:success) }
      it { should_not redirect_to(edit_app_configs_path) }
    end
  end

  describe 'load_configs' do
    it 'should set @app_configs to the first AppConfig' do
      controller.unstub(:load_configs)
      get :index
      expect(assigns(:app_configs)).to eq(AppConfig.first)
    end
  end

  describe 'first_time_user' do
    before(:each) do
      @user = FactoryGirl.create(:user)
      controller.stub(:current_user).and_return(@user)
      controller.unstub(:first_time_user)
    end
    context 'current_user exists' do
      before(:each) do
        get :index
      end
      it { should_not set_the_flash }
      it 'should not redirect' do
        response.should_not be_redirect
      end
    end
    context 'current_user is nil' do
      before(:each) do
        controller.stub(:current_user).and_return(nil)
        get :index
      end
      context 'params[:action] = "terms_of_service"' do
        before(:each) do
          get :terms_of_service
        end
        it { should_not set_the_flash }
        it 'should not redirect' do
          response.should_not be_redirect
        end
      end
      it { should set_the_flash }
      it { should redirect_to(new_user_path) }
    end
  end

  describe 'cart' do
    before(:each) do
      controller.unstub(:cart)
      @user = FactoryGirl.create(:user)
    end
    it 'makes a new cart record for session[:cart] if !cart' do
      get :index
      session[:cart].should be_new_record
      session[:cart].kind_of?(Cart).should be_truthy
    end
    it 'returns session[:cart] if cart.reserver_id' do
      session[:cart] = Cart.new
      session[:cart].reserver_id = @user.id
      get :index
      session[:cart].reserver_id.should == @user.id
    end
    it 'sets the session[:cart].reserver_id to current_user.id if !cart.reserver_id && current_user' do
      controller.stub(:current_user).and_return(@user)
      session[:cart] = Cart.new
      get :index
      session[:cart].reserver_id.should eq(@user.id)
    end
    it 'returns session[:cart] without a reserver_id if !cart.reserver_id && !current_user' do
      session[:cart] = Cart.new
      get :index
      session[:cart].reserver_id.should be_nil
    end
  end

  describe 'set_view_mode' do
    # this has changed as of the resolution of #415
  end

  describe 'current_user' do
    before(:each) do
      controller.unstub(:current_user)
    end
    context '@current_user already exists' do
      it 'should return the current user' do
        @user = FactoryGirl.create(:user)
        controller.instance_variable_set(:@current_user, @user)
        get :index
        expect(assigns(:current_user)).to eq(@user)
      end
    end
    context '@current_user does not already exist' do
      context 'session[:cas_user] exists' do
        it 'should find the current user based on the session :cas_user' do
          @user = FactoryGirl.create(:user)
          session[:cas_user] = @user.login
          get :index
          expect(assigns(:current_user)).to eq(@user)
        end
      end
      context 'session[:cas_user] does not exist' do
        it 'should return nil' do
          get :index
          expect(assigns(:current_user)).to eq(nil)
        end
      end
    end
  end

  describe 'fix_cart_date' do
    before(:each) do
      controller.unstub(:fix_cart_date)
      session[:cart] = Cart.new
      controller.stub(:cart).and_return(session[:cart])
    end
    it 'changes cart.start_date to today if date is in the past' do
      session[:cart].start_date = Date.yesterday
      get :index
      session[:cart].start_date.should eq(Date.today)
    end
    it 'does not change the start_date if date is in the future' do
      session[:cart].start_date = Date.tomorrow
      get :index
      session[:cart].start_date.should eq(Date.tomorrow)
      session[:cart].start_date.should_not eq(Date.today)
    end
  end

end

describe ApplicationController do
  before(:each) do
    @app_config = FactoryGirl.create(:app_config)
    @first_user = FactoryGirl.create(:user) # this is to ensure that all before_filters are run
    controller.stub(:app_setup_check)
    controller.stub(:load_configs)
    controller.stub(:seen_app_configs)
    controller.stub(:first_time_user)
    controller.stub(:cart)
    controller.stub(:fix_cart_date)
    controller.stub(:set_view_mode)
    controller.stub(:current_user)
    controller.stub(:make_cart_compatible)
  end

  #TODO - This may involve rewriting the method somewhat
  describe 'PUT update_cart' do
    before(:each) do
      session[:cart] = Cart.new
      session[:cart].reserver_id = @first_user.id
      session[:cart].start_date = (Date.today + 1.day)
      session[:cart].due_date = (Date.today + 2.days)


      equipment_model = FactoryGirl.create(:equipment_model, category: FactoryGirl.create(:category))
      session[:cart].add_item(equipment_model)
      @new_reserver = FactoryGirl.create(:user)
    end

    context 'valid parameters' do
      it 'should update cart dates' do
        new_start = Date.today + 3.days
        new_end = Date.today + 4.days

        put :update_cart, cart: {start_date_cart: new_start.strftime('%m/%d/%Y'), due_date_cart: new_end.strftime('%m/%d/%Y')}, reserver_id: @new_reserver.id

        session[:cart].start_date.should eq(new_start)
        session[:cart].due_date.should eq(new_end)
        session[:cart].reserver_id.should eq(@new_reserver.id.to_s)
      end

      it 'should not set the flash' do
        flash.should be_empty
      end
    end

    context 'invalid parameters' do
      it 'should set the flash' do
        new_start = Date.today - 300.days
        new_end = Date.today + 4000.days

        put :update_cart, cart: {start_date_cart: new_start.strftime('%m/%d/%Y'), due_date_cart: new_end.strftime('%m/%d/%Y')}, reserver_id: @new_reserver.id

        flash.should_not be_empty
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
      session[:cart].items.should be_empty
    end
    it { should redirect_to(root_path) }
    it { should set_the_flash }
  end

  describe 'GET logout' do
    it 'should always set @current_user to nil' do
      @user = FactoryGirl.create(:user)
      controller.instance_variable_set(:@current_user, @user)
      get :logout
      assigns(:current_user).should be_nil
    end
    it 'should log the user out of CAS' # TODO: figure out how to test this
  end

  describe 'GET terms_of_service' do
    before(:each) do
      @app_config = FactoryGirl.create(:app_config)
      controller.instance_variable_set(:@app_configs, @app_config)
      get :terms_of_service
    end
    it { should render_template('terms_of_service/index') }
    it 'assigns @app_config.terms_of_service to @tos' do
      expect(assigns(:tos)).to eq(@app_config.terms_of_service)
    end
  end

  describe 'PUT deactivate' do
    it 'should assign @objects_class2 to the object and controller specified by params'
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
    it { should render_template('shared/_markdown_help') }
    # TODO: not sure how to make sure that the js template is being rendered as well.
  end
end
