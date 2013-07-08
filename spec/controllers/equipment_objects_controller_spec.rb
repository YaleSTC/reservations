require 'spec_helper'

describe EquipmentObjectsController do
	before(:all) { @app_config = FactoryGirl.create(:app_config) }
	before { @controller.stub(:first_time_user).and_return(:nil) }
	let!(:object) { FactoryGirl.create(:equipment_object) }

	context 'with admin user' do
    before { @controller.stub(:current_user).and_return(FactoryGirl.create(:admin)) }

    describe 'GET index' do
      before { get :index }
      it { should respond_with(:success) }
      it { should render_template(:index) }
      it { should_not set_the_flash }
      context 'without show deleted' do
        context 'with @equipment_model set' do
          it 'should populate an array of all requirements' do
            get :index, equipment_model_id: object.equipment_model
            expect(assigns(:equipment_objects)).to eq(object.equipment_model.equipment_objects)
          end
        end
        context 'without @equipment_model set' do
          it 'should populate an array of all objects' do
            expect(assigns(:equipment_objects)).to eq(EquipmentObject.active)
          end
        end
      end
      context 'with show deleted' do
        context 'with @equipment_model set' do
          it 'should populate an array of all requirements' do
            get :index, equipment_model_id: object.equipment_model, show_deleted: true
            expect(assigns(:equipment_objects)).to eq(object.equipment_model.equipment_objects.active)
          end
        end
        context 'without @equipment_model set' do
          it 'should populate an array of all objects' do
            get :index, show_deleted: true
            expect(assigns(:equipment_objects)).to eq(EquipmentObject.all)
          end     
        end   
      end
    end

    describe 'GET show' do
      before { get :show, id: object }
      it { should respond_with(:success) }
      it { should render_template(:show) }
      it { should_not set_the_flash }
      it 'should set to correct equipment object' do
        expect(assigns(:equipment_object)).to eq(object)
      end
    end
    
    describe 'GET new' do
      before { get :new }
      it { should respond_with(:success) }
      it { should render_template(:new) }
      it { should_not set_the_flash }
      it 'assigns a new equipment object to @equipment_object' do
        assigns(:equipment_object).should be_new_record
        assigns(:equipment_object).should be_kind_of(EquipmentObject)
      end
      it 'sets equipment_model to nil when no equipment model is specified' do
        assigns(:equipment_object).equipment_model.should be_nil
      end
      it 'sets equipment_model when one is passed through params' do
        model = object.equipment_model
        get :new, equipment_model_id: model
        expect(assigns(:equipment_object).equipment_model).to eq(model)
      end
    end
        
    describe 'POST create' do
      context 'with valid attributes' do
        before { post :create, equipment_object: FactoryGirl.attributes_for(:equipment_object,
          serial: "Enter serial # (optional)", equipment_model_id: object.equipment_model.id) }
        it 'should save object' do
          expect{ post :create, equipment_object: FactoryGirl.attributes_for(
            :equipment_object, equipment_model_id: object.equipment_model.id)
            }.to change(EquipmentObject, :count).by(1)
        end
        it { should set_the_flash }
        it { should redirect_to(EquipmentObject.last.equipment_model) }
        it 'should change default serial to nil' do
          EquipmentObject.last.serial.should == nil
        end
      end

      context 'without valid attributes' do
        before { post :create,
          equipment_object: FactoryGirl.attributes_for(:equipment_object, name: nil) }
        it { should_not set_the_flash }
        it { should render_template(:new) }
        it 'should not save' do
          expect{ post :create,equipment_object: FactoryGirl.attributes_for(
            :equipment_object, name: nil) }.not_to change(EquipmentObject, :count)
        end
        it { should render_template(:new) }
      end
    end

    describe 'GET edit' do
      before { get :edit, id: object }
      it { should respond_with(:success) }
      it { should render_template(:edit) }
      it { should_not set_the_flash }
      it 'sets @equipment_object to selected object' do
        expect(assigns(:equipment_object)).to eq(object)
      end
    end
    
    describe 'PUT update' do
      context 'with valid attributes' do
        before { put :update, id: object,
          equipment_object: FactoryGirl.attributes_for(:equipment_object, name: 'Obj') }
        it { should set_the_flash }
        it 'sets @equipment_object to selected object' do
          expect(assigns(:equipment_object)).to eq(object)
        end
        it 'updates attributes' do
          object.reload
          object.name.should == 'Obj'
        end
        it { should redirect_to(object.equipment_model) }
      end

      context 'without valid attributes' do
        before { put :update, id: object,
          equipment_object: FactoryGirl.attributes_for(:equipment_object, name: nil) }
        it { should_not set_the_flash }
        it 'should not update attributes' do
          object.reload
          object.name.should_not be_nil
        end
        it { should render_template(:edit) }
      end
    end

    describe 'DELETE destroy' do
      it 'should remove object from database' do
        expect{ delete :destroy, id: object }.to change(EquipmentObject, :count).by(-1)
      end
      context do
        before { delete :destroy, id: object }
        it { should set_the_flash }
        it { should redirect_to(object.equipment_model) }
        it 'sets @equipment_object to selected object' do
          expect(assigns(:equipment_object)).to eq(object)
        end
      end
    end
  end

  context 'with checkout person user' do
    before { @controller.stub(:current_user).and_return(FactoryGirl.create(:checkout_person)) }
    describe 'GET index' do
      before { get :index }
      it { should respond_with(:success) }
      it { should render_template(:index) }
    end
  end

  context 'with non-admin user' do
    before { @controller.stub(:current_user).and_return(FactoryGirl.create(:user)) }
    it 'GET index should redirect to root' do
      get :index
      response.should redirect_to(root_url)
    end 
    it 'GET show should redirect to root' do
      get :show, id: object
      response.should redirect_to(root_url)
    end
    it 'GET new should redirect to root' do
      get :new
      response.should redirect_to(root_url)
    end
    it 'POST create should redirect to root' do
      post :create, equipment_object: FactoryGirl.attributes_for(:equipment_object)
      response.should redirect_to(root_url)
    end
    it 'GET edit should redirect to root' do
      get :edit, id: object
      response.should redirect_to(root_url)
    end
    it 'PUT update should redirect to root' do
      put :update, id: object, equipment_object: FactoryGirl.attributes_for(:equipment_object)
      response.should redirect_to(root_url)
    end
    it 'DELETE destroy should redirect to root' do
      delete :destroy, id: object
      response.should redirect_to(root_url)
    end
  end
  
	after(:all) { @app_config.destroy }
end