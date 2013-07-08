require 'spec_helper'

describe EquipmentModelsController do
	before(:all) { @app_config = FactoryGirl.create(:app_config) }
	before { @controller.stub(:first_time_user).and_return(:nil) }
	let!(:model) { FactoryGirl.create(:equipment_model) }

  context 'with non-admin user' do
	  before { @controller.stub(:current_user).and_return(FactoryGirl.create(:user)) }
	  context 'GET index should function normally' do
	    before { get :index }
	    it { should respond_with(:success) }
	    it { should render_template(:index) }
	  end 
	  context 'GET show should funciton normally' do
	    before { get :show, id: model }
	    it { should respond_with(:success) }
	    it { should render_template(:show) }
	  end
	  it 'GET new should redirect to root' do
	    get :new
	    response.should redirect_to(root_url)
	  end
	  it 'POST create should redirect to root' do
	    post :create, equipment_model: FactoryGirl.attributes_for(:equipment_model)
	    response.should redirect_to(root_url)
	  end
	  it 'GET edit should redirect to root' do
	    get :edit, id: model
	    response.should redirect_to(root_url)
	  end
	  it 'PUT update should redirect to root' do
	    put :update, id: model, equipment_model: FactoryGirl.attributes_for(:equipment_model)
	    response.should redirect_to(root_url)
	  end
	  it 'DELETE destroy should redirect to root' do
	    delete :destroy, id: model
	    response.should redirect_to(root_url)
	  end
	end

	after(:all) { @app_config.destroy }
end