require 'spec_helper'

describe EquipmentModelsController do
	before(:all) { @app_config = FactoryGirl.create(:app_config) }
	before { @controller.stub(:first_time_user).and_return(:nil) }
	let!(:model) { FactoryGirl.create(:equipment_model) }

	context 'with admin user' do
		before { @controller.stub(:current_user).and_return(FactoryGirl.create(:admin)) }

		describe 'GET index' do
			before { get :index }
      it { should respond_with(:success) }
      it { should render_template(:index) }
      it { should_not set_the_flash }
      context 'without show deleted' do
				let!(:mod_other_cat_active) { FactoryGirl.create(:equipment_model) }
				let!(:mod_other_cat_inactive) { FactoryGirl.create(:equipment_model,
					deleted_at: Date.today) }
        context 'with @category set' do
          it 'should populate an array of of active category-type equipment models' do
          	mod_same_cat_inactive = FactoryGirl.create(:equipment_model,
          		category: model.category, deleted_at: Date.today)
            get :index, category_id: model.category
            assigns(:equipment_models).include?(model).should be_true
            assigns(:equipment_models).include?(mod_other_cat_active).should_not be_true
            assigns(:equipment_models).include?(mod_same_cat_inactive).should_not be_true
            assigns(:equipment_models).include?(mod_other_cat_inactive).should_not be_true 
            expect(assigns(:equipment_models).size).to eq(1)            
          end
        end
        context 'without @category set' do
          it 'should populate an array of all active equipment models' do
            assigns(:equipment_models).include?(model).should be_true
            assigns(:equipment_models).include?(mod_other_cat_active).should be_true
            assigns(:equipment_models).include?(mod_other_cat_inactive).should_not be_true 
            expect(assigns(:equipment_models).size).to eq(2)           
          end
        end
      end
	    context 'with show deleted' do
				let!(:mod_other_cat_active) { FactoryGirl.create(:equipment_model) }
				let!(:mod_other_cat_inactive) { FactoryGirl.create(:equipment_model,
					deleted_at: Date.today) }
        context 'with @category set' do
          it 'should populate an array of category-type equipment models' do
          	mod_same_cat_inactive = FactoryGirl.create(:equipment_model,
          		category: model.category, deleted_at: Date.today)
            get :index, category_id: model.category, show_deleted: true
            assigns(:equipment_models).include?(model).should be_true
            assigns(:equipment_models).include?(mod_other_cat_active).should_not be_true
            assigns(:equipment_models).include?(mod_same_cat_inactive).should be_true            
            assigns(:equipment_models).include?(mod_other_cat_inactive).should_not be_true 
            expect(assigns(:equipment_models).size).to eq(2)      
          end
        end
        context 'without @category set' do
          it 'should populate an array of all equipment models' do
            get :index, show_deleted: true
            assigns(:equipment_models).include?(model).should be_true
            assigns(:equipment_models).include?(mod_other_cat_active).should be_true
            assigns(:equipment_models).include?(mod_other_cat_inactive).should be_true 
            expect(assigns(:equipment_models).size).to eq(3)
          end     
        end   
      end
    end
		
		describe 'GET show' do
      before { get :show, id: model }
      it { should respond_with(:success) }
      it { should render_template(:show) }
      it { should_not set_the_flash }
      it 'should set to correct equipment model' do
        expect(assigns(:equipment_model)).to eq(model)
      end
      it 'should set @associated_equipment_models' do
      	mod1 = FactoryGirl.create(:equipment_model)
      	model.associated_equipment_models = [mod1]
      	get :show, id: model
      	expect(assigns(:associated_equipment_models).size).to eq(1)
      	expect(assigns(:associated_equipment_models)).to eq([] << mod1)
      end
      it 'should limit @associated_equipment_models to maximum 6' do
      	mod1 = FactoryGirl.create(:equipment_model)
      	mod2 = FactoryGirl.create(:equipment_model)
      	mod3 = FactoryGirl.create(:equipment_model)
      	mod4 = FactoryGirl.create(:equipment_model)
      	mod5 = FactoryGirl.create(:equipment_model)
      	mod6 = FactoryGirl.create(:equipment_model)
      	mod7 = FactoryGirl.create(:equipment_model)
      	model.associated_equipment_models = [mod1, mod2, mod3, mod4, mod5, mod6, mod7]
      	get :show, id: model
      	expect(assigns(:associated_equipment_models).size).to eq(6)
      end
    end
		
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

		describe 'POST create' do
      context 'with valid attributes' do
        before { post :create, equipment_model: FactoryGirl.attributes_for(
        	:equipment_model, category_id: model.category) }
        it 'should save model' do
          expect{ post :create, equipment_model: FactoryGirl.attributes_for(
            :equipment_model, category_id: model.category) }.to change(EquipmentModel, :count).by(1)
        end
        it { should set_the_flash }
        it { should redirect_to(EquipmentModel.last) }
      end

      context 'without valid attributes' do
        before { post :create, equipment_model: FactoryGirl.attributes_for(
        	:equipment_model, name: nil) }
        it { should set_the_flash }
        it { should render_template(:new) }
        it 'should not save' do
          expect{ post :create, equipment_model: FactoryGirl.attributes_for(
            :equipment_model, name: nil) }.not_to change(EquipmentModel, :count)
        end
        it { should render_template(:new) }
      end
    end
		
		describe 'PUT update' do
      context 'with valid attributes' do
        before { put :update, id: model, equipment_model:
        	FactoryGirl.attributes_for(:equipment_model, name: 'Mod') }
        it { should set_the_flash }
        it 'sets @equipment_model to selected model' do
          expect(assigns(:equipment_model)).to eq(model)
        end
        it 'updates attributes' do
          model.reload
          model.name.should == 'Mod'
        end
        it { should redirect_to(model) }
      end

      context 'without valid attributes' do
        before { put :update, id: model, equipment_model:
        	FactoryGirl.attributes_for(:equipment_model, name: nil) }
        it { should_not set_the_flash }
        it 'should not update attributes' do
          model.reload
          model.name.should_not be_nil
        end
        it { should render_template(:edit) }
      end
      it 'calls delete_files'
    end

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