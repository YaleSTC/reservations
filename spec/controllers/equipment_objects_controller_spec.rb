require 'spec_helper'

describe EquipmentObjectsController do
	before(:all) { @app_config = FactoryGirl.create(:app_config) }
	before { @controller.stub(:first_time_user).and_return(:nil) }
	let!(:object) { FactoryGirl.create(:equipment_object) }
  let!(:deactivated_object) { FactoryGirl.create(:deactivated) }

  describe 'GET index' do
    context 'with admin user' do
      before do
        @controller.stub(:current_user).and_return(FactoryGirl.create(:admin))
        get :index
      end
      it { should respond_with(:success) }
      it { should render_template(:index) }
      it { should_not set_the_flash }
      context 'without show deleted' do
        let!(:obj_other_cat_active) { FactoryGirl.create(:equipment_object) }
        let!(:obj_other_cat_inactive) { FactoryGirl.create(:equipment_object,
          deleted_at: Date.today) }
        context 'with @equipment_model set' do
          it 'should populate an array of all active model-type equipment objects' do
            obj_same_cat_inactive = FactoryGirl.create(:equipment_object,
              equipment_model: object.equipment_model, deleted_at: Date.today)
            get :index, equipment_model_id: object.equipment_model
            assigns(:equipment_objects).include?(object).should be_truthy
            assigns(:equipment_objects).include?(obj_other_cat_active).should_not be_truthy
            assigns(:equipment_objects).include?(obj_same_cat_inactive).should_not be_truthy
            assigns(:equipment_objects).include?(obj_other_cat_inactive).should_not be_truthy
            expect(assigns(:equipment_objects).size).to eq(1)
          end
        end
        context 'without @equipment_model set' do
          it 'should populate an array of all active equipment objects' do
            assigns(:equipment_objects).include?(object).should be_truthy
            assigns(:equipment_objects).include?(obj_other_cat_active).should be_truthy
            assigns(:equipment_objects).include?(obj_other_cat_inactive).should_not be_truthy
            expect(assigns(:equipment_objects).size).to eq(2)
          end
        end
      end
      context 'with show deleted' do
        let!(:obj_other_cat_active) { FactoryGirl.create(:equipment_object) }
        let!(:obj_other_cat_inactive) { FactoryGirl.create(:equipment_object,
          deleted_at: Date.today) }
        context 'with @equipment_model set' do
          it 'should populate an array of all model-type equipment objects' do
            obj_same_cat_inactive = FactoryGirl.create(:equipment_object,
              equipment_model: object.equipment_model, deleted_at: Date.today)
            get :index, equipment_model_id: object.equipment_model, show_deleted: true
            assigns(:equipment_objects).include?(object).should be_truthy
            assigns(:equipment_objects).include?(obj_other_cat_active).should_not be_truthy
            assigns(:equipment_objects).include?(obj_same_cat_inactive).should be_truthy
            assigns(:equipment_objects).include?(obj_other_cat_inactive).should_not be_truthy
            expect(assigns(:equipment_objects).size).to eq(2)
          end
        end
        context 'without @equipment_model set' do
          it 'should populate an array of all equipment objects' do
            get :index, show_deleted: true
            assigns(:equipment_objects).include?(object).should be_truthy
            assigns(:equipment_objects).include?(obj_other_cat_active).should be_truthy
            assigns(:equipment_objects).include?(obj_other_cat_inactive).should be_truthy
            expect(assigns(:equipment_objects).size).to eq(4)
          end
        end
      end
    end
    context 'with checkout person user' do
      before do
        @controller.stub(:current_user).and_return(FactoryGirl.create(:checkout_person))
        get :index
      end
      it { should respond_with(:success) }
      it { should render_template(:index) }
    end
    context 'with non-admin user' do
      before { @controller.stub(:current_user).and_return(FactoryGirl.create(:user)) }
      it 'should redirect to root' do
        get :index
        response.should redirect_to(root_url)
      end
    end
  end

  describe 'GET show' do
    context 'with admin user' do
      before do
        @controller.stub(:current_user).and_return(FactoryGirl.create(:admin))
        get :show, id: object
      end
      it { should respond_with(:success) }
      it { should render_template(:show) }
      it { should_not set_the_flash }
      it 'should set to correct equipment object' do
        expect(assigns(:equipment_object)).to eq(object)
      end
    end
    context 'with non-admin user' do
      before do
        @controller.stub(:current_user).and_return(FactoryGirl.create(:user))
        get :show, id: object
      end
      it 'should redirect to root' do
        get :show, id: object
        response.should redirect_to(root_url)
      end
    end
  end

  describe 'GET new' do
    context 'with admin user' do
      before do
        @controller.stub(:current_user).and_return(FactoryGirl.create(:admin))
        get :new
      end
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
    context 'with non-admin user' do
      before do
        @controller.stub(:current_user).and_return(FactoryGirl.create(:user))
        get :new
      end
      it 'should redirect to root' do
        get :new
        response.should redirect_to(root_url)
      end
    end
  end

  describe 'POST create' do
    context 'with admin user' do
      before { @controller.stub(:current_user).and_return(FactoryGirl.create(:admin)) }
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
        before { post :create, equipment_object: FactoryGirl.attributes_for(
          :equipment_object, name: nil) }
        it { should_not set_the_flash }
        it { should render_template(:new) }
        it 'should not save' do
          expect{ post :create, equipment_object: FactoryGirl.attributes_for(
            :equipment_object, name: nil) }.not_to change(EquipmentObject, :count)
        end
        it { should render_template(:new) }
      end
    end
    context 'with non-admin user' do
      before { @controller.stub(:current_user).and_return(FactoryGirl.create(:user)) }
      it 'should redirect to root' do
        post :create, equipment_object: FactoryGirl.attributes_for(:equipment_object)
        response.should redirect_to(root_url)
      end
    end
  end

  describe 'GET edit' do
    context 'with admin user' do
      before do
        @controller.stub(:current_user).and_return(FactoryGirl.create(:admin))
        get :edit, id: object
      end
      it { should respond_with(:success) }
      it { should render_template(:edit) }
      it { should_not set_the_flash }
      it 'sets @equipment_object to selected object' do
        expect(assigns(:equipment_object)).to eq(object)
      end
    end
    context 'with non-admin user' do
      before { @controller.stub(:current_user).and_return(FactoryGirl.create(:user)) }
      it 'should redirect to root' do
        get :edit, id: object
        response.should redirect_to(root_url)
      end
    end
  end

  describe 'PUT update' do
    context 'with admin user' do
      before { @controller.stub(:current_user).and_return(FactoryGirl.create(:admin)) }
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
    context 'with non-admin user' do
      before { @controller.stub(:current_user).and_return(FactoryGirl.create(:user)) }
      it 'should redirect to root' do
        put :update, id: object, equipment_object: FactoryGirl.attributes_for(:equipment_object)
        response.should redirect_to(root_url)
      end
    end
  end

  describe 'DELETE destroy' do
    context 'with admin user' do
      before { @controller.stub(:current_user).and_return(FactoryGirl.create(:admin)) }
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
    context 'with non-admin user' do
      before { @controller.stub(:current_user).and_return(FactoryGirl.create(:user)) }
      it 'should redirect to root' do
        delete :destroy, id: object
        response.should redirect_to(root_url)
      end
    end
  end

	describe 'PUT deactivate' do
    before { request.env['HTTP_REFERER'] = '/referrer' }
    context 'with admin user' do
      before do
        @controller.stub(:current_user).and_return(FactoryGirl.create(:admin))
        put :deactivate, id: object, deactivation_reason: "Because I can"
        object.reload
      end
      it { response.should be_redirect }

      subject { object }
      its(:deactivation_reason) { should == "Because I can" }
    end

    context 'with non-admin user' do
      before do
        @controller.stub(:current_user).and_return(FactoryGirl.create(:user))
      end
      it 'should redirect to root' do
        put :deactivate, id: object, deactivation_reason: "Because I can't"
        response.should redirect_to(root_url)
      end
    end
	end

	describe 'PUT activate' do
    before { request.env['HTTP_REFERER'] = '/referrer' }
    context 'with admin user' do
      before do
        @controller.stub(:current_user).and_return(FactoryGirl.create(:admin))
        put :activate, id: deactivated_object
        deactivated_object.reload
      end

      it { response.should be_redirect }

      subject { deactivated_object }
      its(:deactivation_reason) { should == nil }
    end

    context 'with non-admin user' do
      before do
        @controller.stub(:current_user).and_return(FactoryGirl.create(:user))
      end

      it 'should redirect to root' do
        put :activate, id: object
        response.should redirect_to(root_url)
      end
    end
	end

	after(:all) { @app_config.destroy }
end
