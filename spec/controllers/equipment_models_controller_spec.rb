require 'spec_helper'

describe EquipmentModelsController do
	before(:all) { @app_config = FactoryGirl.create(:app_config) }
	before { @controller.stub(:first_time_user).and_return(:nil) }
	let!(:model) { FactoryGirl.create(:equipment_model) }

	context 'with admin user' do
		before { @controller.stub(:current_user).and_return(FactoryGirl.create(:admin)) }

		describe 'GET index'
		
		describe 'GET show'
		
    describe 'GET new' do
      before { get :new }
      it { should respond_with(:success) }
      it { should render_template(:new) }
      it { should_not set_the_flash }
      it 'assigns a new equipment model to @equipment_model' do
        assigns(:equipment_model).should be_new_record
        assigns(:equipment_model).should be_kind_of(EquipmentModel)
      end
      it 'sets equipment_model to nil when no category is specified' do
        assigns(:equipment_model).category.should be_nil
      end
      it 'sets category when one is passed through params' do
        cat = model.category
        get :new, category_id: cat
        expect(assigns(:equipment_model).category).to eq(cat)
      end
    end

    describe 'GET edit' do
      before { get :edit, id: model }
      it { should respond_with(:success) }
      it { should render_template(:edit) }
      it { should_not set_the_flash }
      it 'sets @equipment_model to selected model' do
        expect(assigns(:equipment_model)).to eq(model)
      end
    end

		describe 'POST create'
		
		describe 'PUT update'

		describe 'DELETE destroy' do
			it 'should remove model from database' do
        expect{ delete :destroy, id: model }.to change(EquipmentModel, :count).by(-1)
      end
      context do
        before { delete :destroy, id: model }
        it 'sets @equipment_object to selected model' do
          expect(assigns(:equipment_model)).to eq(model)
        end
        it { should set_the_flash }
        it { should redirect_to(equipment_models_url) }
      end
    end
	end

  context 'with non-admin user' do
	  before { @controller.stub(:current_user).and_return(FactoryGirl.create(:user)) }
	  describe 'GET index should function normally' do
	    before { get :index }
	    it { should respond_with(:success) }
	    it { should render_template(:index) }
	  end 
	  describe 'GET show should funciton normally' do
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