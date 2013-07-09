require 'spec_helper'

class TestController < ApplicationController
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
end

describe TestController, focus: true do
  before(:each) do
    @first_user = FactoryGirl.create(:user) # this is to ensure that all before_filters are run
    controller.stub(:app_setup)
    controller.stub(:load_configs)
    controller.stub(:first_time_user)
    controller.stub(:cart)
    controller.stub(:fix_cart_date)
    controller.stub(:set_view_mode)
    controller.stub(:current_user)
    controller.stub(:check_if_is_admin)
  end

  describe 'app_setup' do
    # this has changed as a result of issue #415
  end

  describe 'load_configs' do
    it 'should set @app_configs to the first AppConfig' do
      AppConfig.destroy_all
      @app_config = FactoryGirl.create(:app_config)
      controller.unstub(:load_configs)
      get :index
      expect(assigns(:app_configs)).to eq(@app_config)
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
      session[:cart].kind_of?(Cart).should be_true
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

  describe 'check_if_is_admin' do
    before(:each) do
      controller.unstub(:check_if_is_admin)
    end
    context 'user is an admin' do
      before(:each) do
        @admin = FactoryGirl.create(:admin)
        controller.stub(:current_user).and_return(@admin)
        get :activate
        get :deactivate
      end
      it { should_not set_the_flash }
      it 'should not redirect' do
        response.should_not be_redirect
      end
    end
    context 'user is not an admin' do
      before(:each) do
        @user = FactoryGirl.create(:user)
        controller.stub(:current_user).and_return(@user)
        request.env["HTTP_REFERER"] = "where_i_came_from"
        get :deactivate
        get :activate
      end
      it { should set_the_flash }
      it { should redirect_to(request.referer) }
    end
  end

  describe 'update_cart'
  describe 'fix_cart_date'
  describe 'empty_cart'
  describe 'logout'
  describe 'require_admin'
  describe 'require_checkout_person'
  describe 'require_login'
  describe 'require_user'
  describe 'require_user_or_checkout_person'
  describe 'restricted_redirect_to'
  describe 'terms_of_service'
  describe 'deactivate'
  describe 'activate'
  describe 'markdown_help'
end
