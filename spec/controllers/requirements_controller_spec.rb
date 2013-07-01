require 'spec_helper'

describe RequirementsController do
  before(:each) do
    # ApplicationController.class.skip_before_filter RubyCAS::Filter
    # # ApplicationController.skip_before_filter :current_user
    # ApplicationController.class.skip_before_filter :first_time_user
    # # ApplicationController.skip_before_filter :cart
    # # ApplicationController.skip_before_filter :fix_cart_date
    # # ApplicationController.skip_before_filter :set_view_mode
    # ApplicationController.class.skip_before_filter :app_setup
    # # ApplicationController.skip_before_filter :load_configs
    # RequirementsController.class.skip_before_filter :require_admin

    # set the application configs
    @app_config = FactoryGirl.create(:app_config)
    # create an admin user in admin mode
    @user = FactoryGirl.create(:admin, login: 'dasdf34')
    # set current_user
    session[:current_user] = @user
  end
  describe 'GET index' do
    before(:each) do
      @requirement = FactoryGirl.create(:requirement)
      get :index
    end
    # it "what does it redirect to?" do
    #   response.should redirect_to(catalog_path)
    # end
    it { should respond_with(:success) }
    it { should render_template(:index) }
    it { should_not set_the_flash }
    it 'should populate an array of all requirements' do
      expect(assigns(:requirements)).to eq([@requirement])
    end
  end
  describe 'GET #show' do
    it 'should assign the selected requirement to @requirement'
    it 'should render the :show view'
  end
  describe 'GET #new' do
    it 'should render the :new view'
    it 'assigns a new requirement to @requirement'

  end
  describe 'PUT #update' do
    context 'with valid attributes' do
    end
    context 'with invalid attributes' do
    end
  end
  describe 'POST #create' do
    context 'with valid attributes' do
      it 'saves a new requirement'
      it 'redirects to the show page for the new requirement'
      it 'flashes a success message'
    end
    context 'with invalid attributes' do
      it 'fails to save a new requirment'
      it 'redirects back to the :new view'
      it 'flashes errors'
    end
  end
  describe 'DELETE #destroy' do
    it 'assigns the selected requirement to @requirement'
    it 'removes @requirement from the database'
    it 'redirects to the :index view'
  end
  after(:all) do
    @current_user = nil
    @app_config = nil
    @user.destroy
  end
end
