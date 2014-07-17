require 'spec_helper'

describe CatalogController do
  before(:each) do
    @app_config = FactoryGirl.create(:app_config)
    @user = FactoryGirl.create(:user)
    @cart = FactoryGirl.build(:cart, reserver_id: @user.id)
    @controller.stub(:current_user).and_return(@user)
    @controller.stub(:first_time_user).and_return(nil)
    #@controller.stub(:cart).and_return(session[@cart])
    #@controller.stub(:fix_cart_date)
  end
  describe 'GET index' do
    before(:each) do
      get :index, {}#, { cart: @cart } # the first hash passed here is params[] and the second is session[]
    end
    it 'sets @reserver_id to the current cart.reserver_id' do
      expect(assigns(:reserver_id)).to eq(@user.id)
    end
    it { should respond_with(:success) }
    it { should render_template(:index) }
    it { should_not set_the_flash }
  end
  describe 'PUT add_to_cart' do
    context 'valid equipment_model selected' do
      before(:each) do
        @equipment_model = FactoryGirl.create(:equipment_model)
        put :add_to_cart, id: @equipment_model.id
      end
      it 'should call cart.add_item to add item to cart' do
        expect{
          put :add_to_cart, id: @equipment_model.id
        }.to change{session[:cart].items[@equipment_model.id]}.by(1)

      end
      it 'should set flash[:error] if errors exist' do
        @cart.stub(:validate_items).and_return("test")
        @cart.stub(:validate_dates_and_items).and_return("test2")
        flash[:error].should_not be_nil
      end
      it { should redirect_to(root_path) }
      it { should render_template(:action => 'update_cart') }
    end
    context 'invalid equipment_model selected' do
      before(:each) do
        put :add_to_cart, { :id => 1 } # there are no equipment models in the db so this is invalid
      end
      it { should redirect_to(root_path) }
      it { should set_the_flash }
      it 'should add logger error' do
        Rails.logger.should_receive(:error).with("Attempt to add invalid equipment model #{1}")
        put :add_to_cart, { :id => 1 } # this call has to come after the previous line
      end
    end
  end
  describe 'PUT remove_from_cart' do
    context 'valid equipment_model selected' do
      before(:each) do
        @equipment_model = FactoryGirl.create(:equipment_model)
        put :add_to_cart, id: @equipment_model.id
        put :remove_from_cart, id: @equipment_model.id
      end
      it 'should call cart.remove_item to remove item from cart' do
        put :add_to_cart, id: @equipment_model.id
        expect{
          put :remove_from_cart, id: @equipment_model.id
        }.to change{session[:cart].items.size}.by(-1)
      end
      it 'should set flash[:error] to the result of Reservation.validate_set if exists' do
        Reservation.stub(:validate_set).with(session[:cart].reserver, session[:cart].prepare_all).and_return("test")
        flash[:error].should_not be_nil
      end
      it { should redirect_to(root_path) }
      it { should render_template(:action => 'update_cart') }
    end
    context 'invalid equipment_model selected' do
      before(:each) do
        put :remove_from_cart, id: 1
      end
      it { should redirect_to(root_path) }
      it { should set_the_flash }
      it 'should add logger error' do
        Rails.logger.should_receive(:error).with("Attempt to add invalid equipment model #{1}")
        put :remove_from_cart, id: 1
      end
    end
  end
  describe 'PUT update_user_per_cat_page' do
    before(:each) do
      put :update_user_per_cat_page
    end
    it 'should set session[:items_per_page] to params[items_per_page] if exists' do
      put :update_user_per_cat_page, :items_per_page => 20
      session[:items_per_page].should eq('20')
    end
    it 'should not alter session[:items_per_page] if params[:items_per_page] is nil' do
      session[:items_per_page] = '15'
      put :update_user_per_cat_page, :items_per_page => nil
      session[:items_per_page].should_not eq(nil)
      session[:items_per_page].should eq('15')
    end
    it { should redirect_to(root_path) }
    it { should render_template(:action => 'cat_pagination')}
  end

  # I don't like that this test is actually searching the database, but unfortunately
  # I couldn't get the model methods to stub correctly
  describe 'PUT search' do
    context 'query is blank' do
      before(:each) do
        put :search, { query: '' }
      end
      it { should redirect_to(root_path) }
    end
    context 'query is not blank' do
      it 'should call catalog_search on EquipmentModel and return active equipment models' do
        @equipment_model = FactoryGirl.create(:equipment_model, active: true, description: 'query')
        #EquipmentModel.stub(:catelog_search).with('query').and_return(@equipment_model)
        put :search, { query: 'query' }
        expect(assigns(:equipment_model_results)).to eq([@equipment_model])
      end
      it 'should call catalog_search on EquipmentObject' do
        @equipment_object = FactoryGirl.create(:equipment_object, serial: 'query')
        #EquipmentObject.stub(:catelog_search).with('query').and_return(@equipment_object)
        put :search, { query: 'query' }
        expect(assigns(:equipment_object_results)).to eq([@equipment_object])
      end
      it 'should call catalog_search on Category' do
        @category = FactoryGirl.create(:category, name: 'query')
        #Category.stub(:catelog_search).with('query').and_return(@category)
        put :search, { query: 'query' }
        expect(assigns(:category_results)).to eq([@category])
      end
      it { should render_template(:action => 'search_results') }
    end
  end
end
