require 'spec_helper'

describe EquipmentItemsController, type: :controller do
  before(:all) { @app_config = FactoryGirl.create(:app_config) }
  let!(:object) { FactoryGirl.create(:equipment_item) }
  let!(:deactivated_object) { FactoryGirl.create(:deactivated) }

  describe 'GET index' do
    context 'with admin user' do
      before do
        sign_in FactoryGirl.create(:admin)
        get :index
      end
      it { is_expected.to respond_with(:success) }
      it { is_expected.to render_template(:index) }
      it { is_expected.not_to set_the_flash }
      context 'without show deleted' do
        let!(:obj_other_cat_active) { FactoryGirl.create(:equipment_item) }
        let!(:obj_other_cat_inactive) do
          FactoryGirl.create(:equipment_item,
                             deleted_at: Date.current)
        end
        context 'with @equipment_model set' do
          it 'should populate an array of all active model-type equipment '\
            'objects' do
            obj_same_cat_inactive =
              FactoryGirl.create(:equipment_item,
                                 equipment_model: object.equipment_model,
                                 deleted_at: Date.current)
            get :index, equipment_model_id: object.equipment_model
            expect(assigns(:equipment_items).include?(object)).to be_truthy
            expect(assigns(:equipment_items)
              .include?(obj_other_cat_active)).not_to be_truthy
            expect(assigns(:equipment_items)
              .include?(obj_same_cat_inactive)).not_to be_truthy
            expect(assigns(:equipment_items)
              .include?(obj_other_cat_inactive)).not_to be_truthy
            expect(assigns(:equipment_items).size).to eq(1)
          end
        end
        context 'without @equipment_model set' do
          it 'should populate an array of all active equipment items' do
            expect(assigns(:equipment_items).include?(object)).to be_truthy
            expect(assigns(:equipment_items)
              .include?(obj_other_cat_active)).to be_truthy
            expect(assigns(:equipment_items)
              .include?(obj_other_cat_inactive)).not_to be_truthy
            expect(assigns(:equipment_items).size).to eq(2)
          end
        end
      end
      context 'with show deleted' do
        let!(:obj_other_cat_active) { FactoryGirl.create(:equipment_item) }
        let!(:obj_other_cat_inactive) do
          FactoryGirl.create(:equipment_item,
                             deleted_at: Date.current)
        end
        context 'with @equipment_model set' do
          it 'should populate an array of all model-type equipment items' do
            obj_same_cat_inactive =
              FactoryGirl.create(:equipment_item,
                                 equipment_model: object.equipment_model,
                                 deleted_at: Date.current)
            get :index, equipment_model_id: object.equipment_model,
                        show_deleted: true
            expect(assigns(:equipment_items).include?(object)).to be_truthy
            expect(assigns(:equipment_items)
              .include?(obj_other_cat_active)).not_to be_truthy
            expect(assigns(:equipment_items)
              .include?(obj_same_cat_inactive)).to be_truthy
            expect(assigns(:equipment_items)
              .include?(obj_other_cat_inactive)).not_to be_truthy
            expect(assigns(:equipment_items).size).to eq(2)
          end
        end
        context 'without @equipment_model set' do
          it 'should populate an array of all equipment items' do
            get :index, show_deleted: true
            expect(assigns(:equipment_items).include?(object)).to be_truthy
            expect(assigns(:equipment_items)
              .include?(obj_other_cat_active)).to be_truthy
            expect(assigns(:equipment_items)
              .include?(obj_other_cat_inactive)).to be_truthy
            expect(assigns(:equipment_items).size).to eq(4)
          end
        end
      end
    end
    context 'with checkout person user' do
      before do
        sign_in FactoryGirl.create(:checkout_person)
        get :index
      end
      it { is_expected.to respond_with(:success) }
      it { is_expected.to render_template(:index) }
    end
    context 'with non-admin user' do
      before { sign_in FactoryGirl.create(:user) }
      it 'should redirect to root' do
        get :index
        expect(response).to redirect_to(root_url)
      end
    end
  end

  describe 'GET show' do
    context 'with admin user' do
      before do
        sign_in FactoryGirl.create(:admin)
        get :show, id: object
      end
      it { is_expected.to respond_with(:success) }
      it { is_expected.to render_template(:show) }
      it { is_expected.not_to set_the_flash }
      it 'should set to correct equipment item' do
        expect(assigns(:equipment_item)).to eq(object)
      end
    end
    context 'with non-admin user' do
      before do
        sign_in FactoryGirl.create(:user)
        get :show, id: object
      end
      it 'should redirect to root' do
        get :show, id: object
        expect(response).to redirect_to(root_url)
      end
    end
  end

  describe 'GET new' do
    context 'with admin user' do
      before do
        sign_in FactoryGirl.create(:admin)
        get :new
      end
      it { is_expected.to respond_with(:success) }
      it { is_expected.to render_template(:new) }
      it { is_expected.not_to set_the_flash }
      it 'assigns a new equipment item to @equipment_item' do
        expect(assigns(:equipment_item)).to be_new_record
        expect(assigns(:equipment_item)).to be_kind_of(EquipmentItem)
      end
      it 'sets equipment_model to nil when no equipment model is specified' do
        expect(assigns(:equipment_item).equipment_model).to be_nil
      end
      it 'sets equipment_model when one is passed through params' do
        model = object.equipment_model
        get :new, equipment_model_id: model
        expect(assigns(:equipment_item).equipment_model).to eq(model)
      end
    end
    context 'with non-admin user' do
      before do
        sign_in FactoryGirl.create(:user)
        get :new
      end
      it 'should redirect to root' do
        get :new
        expect(response).to redirect_to(root_url)
      end
    end
  end

  describe 'POST create' do
    context 'with admin user' do
      before { sign_in FactoryGirl.create(:admin) }
      context 'with valid attributes' do
        before do
          post :create,
               equipment_item: FactoryGirl
                 .attributes_for(:equipment_item,
                                 serial: 'Enter serial # (optional)',
                                 equipment_model_id: object.equipment_model.id)
        end
        it 'should save object with notes' do
          expect do
            post :create, equipment_item: FactoryGirl.attributes_for(
            :equipment_item, equipment_model_id: object.equipment_model.id)
          end.to change(EquipmentItem, :count).by(1)
          expect(EquipmentItem.last.notes).not_to be_nil
          expect(EquipmentItem.last.notes).not_to be('')
        end
        it { is_expected.to set_the_flash }
        it { is_expected.to redirect_to(EquipmentItem.last.equipment_model) }
      end
      context 'without valid attributes' do
        before do
          post :create, equipment_item: FactoryGirl.attributes_for(
          :equipment_item, name: nil)
        end
        it { is_expected.not_to set_the_flash }
        it { is_expected.to render_template(:new) }
        it 'should not save' do
          expect do
            post :create, equipment_item: FactoryGirl.attributes_for(
            :equipment_item, name: nil)
          end.not_to change(EquipmentItem, :count)
        end
        it { is_expected.to render_template(:new) }
      end
    end
    context 'with non-admin user' do
      before { sign_in FactoryGirl.create(:user) }
      it 'should redirect to root' do
        post :create,
             equipment_item: FactoryGirl.attributes_for(:equipment_item)
        expect(response).to redirect_to(root_url)
      end
    end
  end

  describe 'GET edit' do
    context 'with admin user' do
      before do
        sign_in FactoryGirl.create(:admin)
        get :edit, id: object
      end
      it { is_expected.to respond_with(:success) }
      it { is_expected.to render_template(:edit) }
      it { is_expected.not_to set_the_flash }
      it 'sets @equipment_item to selected object' do
        expect(assigns(:equipment_item)).to eq(object)
      end
    end
    context 'with non-admin user' do
      before { sign_in FactoryGirl.create(:user) }
      it 'should redirect to root' do
        get :edit, id: object
        expect(response).to redirect_to(root_url)
      end
    end
  end

  describe 'PUT update' do
    context 'with admin user' do
      before { sign_in FactoryGirl.create(:admin) }
      context 'with valid attributes' do
        before do
          put :update,
              id: object,
              equipment_item: FactoryGirl.attributes_for(:equipment_item,
                                                           name: 'Obj')
        end
        it { is_expected.to set_the_flash }
        it 'sets @equipment_item to selected object' do
          expect(assigns(:equipment_item)).to eq(object)
        end
        it 'updates attributes' do
          object.reload
          expect(object.name).to eq('Obj')
        end
        it 'updates notes' do
          expect { object.reload }.to change(object, :notes)
        end
        it { is_expected.to redirect_to(object) }
      end
      context 'without valid attributes' do
        before do
          put :update,
              id: object,
              equipment_item: FactoryGirl.attributes_for(:equipment_item,
                                                           name: nil)
        end
        it { is_expected.not_to set_the_flash }
        it 'should not update attributes' do
          object.reload
          expect(object.name).not_to be_nil
        end
        it { is_expected.to render_template(:edit) }
      end
    end
    context 'with non-admin user' do
      before { sign_in FactoryGirl.create(:user) }
      it 'should redirect to root' do
        put :update,
            id: object,
            equipment_item: FactoryGirl.attributes_for(:equipment_item)
        expect(response).to redirect_to(root_url)
      end
    end
  end

  describe 'PUT deactivate' do
    before { request.env['HTTP_REFERER'] = '/referrer' }
    context 'with admin user' do
      before do
        sign_in FactoryGirl.create(:admin)
        put :deactivate, id: object, deactivation_reason: 'Because I can'
        object.reload
      end
      it { expect(response).to be_redirect }
      it { expect(object.deactivation_reason).to eq('Because I can') }
      it 'should change the notes' do
        new_object = FactoryGirl.create(:equipment_item)
        put :deactivate, id: new_object, deactivation_reason: 'reason'
        expect { new_object.reload }.to change(new_object, :notes)
      end
    end

    context 'with non-admin user' do
      before do
        sign_in FactoryGirl.create(:user)
      end
      it 'should redirect to root' do
        put :deactivate, id: object, deactivation_reason: "Because I can't"
        expect(response).to redirect_to(root_url)
      end
    end
  end

  describe 'PUT activate' do
    before { request.env['HTTP_REFERER'] = '/referrer' }
    context 'with admin user' do
      before do
        sign_in FactoryGirl.create(:admin)
        put :activate, id: deactivated_object
        deactivated_object.reload
      end

      it { expect(response).to be_redirect }
      it { expect(deactivated_object.deactivation_reason).to be_nil }

      it 'should change the notes' do
        new_object = FactoryGirl.create(:equipment_item)
        put :activate, id: new_object
        expect { new_object.reload }.to change(new_object, :notes)
      end
    end

    context 'with non-admin user' do
      before do
        sign_in FactoryGirl.create(:user)
      end

      it 'should redirect to root' do
        put :activate, id: object
        expect(response).to redirect_to(root_url)
      end
    end
  end

  after(:all) { @app_config.destroy }
end
