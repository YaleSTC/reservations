require 'spec_helper'

describe ApplicationController, focus: true do
  before(:all) do
    @app_config = FactoryGirl.create(:app_config)
  end

  # an anonymous controller used to test the before_filters in application controller
  controller do
    before_filter :load_configs
    def index
      render :text => "Hello"
    end
  end

  describe 'app_setup' do
    # this has changed as a result of issue #415
  end
  describe 'load_configs' do
    it 'should set @app_configs to the first AppConfig' do
      get :index
      expect(assigns(:app_configs)).to eq(@app_config)
    end
  end
  describe 'first_time_user'
  describe 'cart'
  describe 'set_view_mode'
  describe 'current_user'
  describe 'check_if_is_admin'
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
  after(:all) do
    @app_config.destroy
  end
end
