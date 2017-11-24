# frozen_string_literal: true

require 'spec_helper'

describe EquipmentModelsController, type: :controller do
  before(:each) { mock_app_config(requests_affect_availability: false) }
  it_behaves_like 'calendarable', EquipmentModel

  USER_ROLES = %i[admin user].freeze

  describe 'GET index' do
    shared_examples_for 'GET index success' do |user_role|
      before do
        mock_user_sign_in(UserMock.new(user_role))
      end

      describe 'basic function' do
        before { get :index }
        it_behaves_like 'successful request', :index
      end

      it 'defaults to all active equipment models' do
        # UNSAFE, but a stand in for a relation
        models = spy('Array')
        # get around the eager loading
        allow(models).to receive(:includes).and_return(models)
        allow(EquipmentModel).to receive(:where).and_return([])
        allow(EquipmentModel).to receive(:all).and_return(models)
        get :index
        expect(EquipmentModel).to have_received(:all)
        expect(models).to have_received(:active)
      end

      context '@category set' do
        it 'restricts results to category' do
          models = spy('Array')
          cat = CategoryMock.new(traits: [:findable,
                                          [:with_equipment_models,
                                           models: models]])
          allow(models).to receive(:includes).and_return(models)
          allow(EquipmentModel).to receive(:where).and_return([])
          get :index, params: { category_id: cat.id }
          expect(cat).to have_received(:equipment_models)
          expect(models).to have_received(:active)
        end
      end

      context 'with show deleted' do
        it 'populates an array of all equipment models' do
          models = spy('Array')
          allow(EquipmentModel).to receive(:where).and_return([])
          allow(EquipmentModel).to receive(:all).and_return(models)
          get :index, params: { show_deleted: true }
          expect(EquipmentModel).to have_received(:all)
          expect(models).to have_received(:includes)
          expect(models).not_to have_received(:active)
        end
      end
    end
    USER_ROLES.each { |type| it_behaves_like 'GET index success', type }
  end

  describe 'GET new' do
    context 'with admin user' do
      before do
        mock_user_sign_in(UserMock.new(:admin))
        get :new
      end
      it_behaves_like 'successful request', :new
      it 'assigns a new equipment model to @equipment_model' do
        expect(assigns(:equipment_model)).to be_new_record
        expect(assigns(:equipment_model)).to be_kind_of(EquipmentModel)
      end
      it 'sets category when one is passed through params' do
        cat = CategoryMock.new(traits: [:findable])
        allow(EquipmentModel).to receive(:new)
        get :new, params: { category_id: cat.id }
        expect(EquipmentModel).to have_received(:new).with(category: cat)
      end
    end
    context 'when not admin' do
      before do
        mock_user_sign_in
        get :new
      end
      it_behaves_like 'redirected request'
    end
  end

  describe 'POST create' do
    context 'with admin user' do
      before { mock_user_sign_in(UserMock.new(:admin)) }
      context 'successful save' do
        let!(:model) { FactoryGirl.build_stubbed(:equipment_model) }
        before do
          allow(EquipmentModel).to receive(:new).and_return(model)
          allow(model).to receive(:save).and_return(true)
          post :create, params: { equipment_model: { name: 'Model' } }
        end
        it { is_expected.to set_flash[:notice] }
        it { is_expected.to redirect_to(model) }
      end

      context 'unsuccessful save' do
        before do
          model = EquipmentModelMock.new(save: false)
          post :create, params: { equipment_model: { id: model.id } }
        end
        it { is_expected.to set_flash[:error] }
        it { is_expected.to render_template(:new) }
      end
    end

    context 'when not admin' do
      before do
        mock_user_sign_in
        attr = FactoryGirl.attributes_for(:equipment_model)
        post :create, params: { equipment_model: attr }
      end
      it_behaves_like 'redirected request'
    end
  end

  describe 'PUT update' do
    context 'with admin user' do
      before { mock_user_sign_in(UserMock.new(:admin)) }
      context 'successful update' do
        let!(:model) { FactoryGirl.build_stubbed(:equipment_model) }
        before do
          allow(EquipmentModel).to receive(:find).with(model.id.to_s)
                                                 .and_return(model)
          allow(model).to receive(:update_attributes).and_return(true)
          put :update,
              params: { id: model.id, equipment_model: { name: 'Model' } }
        end
        it { is_expected.to set_flash[:notice] }
        it { is_expected.to redirect_to(model) }
      end

      context 'unsuccessful update' do
        before do
          model = EquipmentModelMock.new(traits: %i[findable with_category],
                                         update_attributes: false)
          put :update,
              params: { id: model.id, equipment_model: { name: 'Model' } }
        end
        it { is_expected.not_to set_flash }
        it { is_expected.to render_template(:edit) }
      end
    end
    context 'when not admin' do
      before do
        mock_user_sign_in
        put :update,
            params: { id: 1, equipment_model: { name: 'Model' } }
      end
      it_behaves_like 'redirected request'
    end
  end

  describe 'PUT deactivate' do
    context 'as admin' do
      before { mock_user_sign_in(UserMock.new(:admin)) }
      shared_examples 'not confirmed' do |flash_type, **opts|
        let!(:model) { FactoryGirl.build_stubbed(:equipment_model) }
        before do
          allow(EquipmentModel).to receive(:find).with(model.id.to_s)
                                                 .and_return(model)
          allow(model).to receive(:destroy)
          put :deactivate, params: { id: model.id, **opts }
        end
        it { is_expected.to set_flash[flash_type] }
        it { is_expected.to redirect_to(model) }
        it 'does not deactivate model' do
          expect(model).not_to have_received(:destroy)
        end
      end
      it_behaves_like 'not confirmed', :error
      it_behaves_like 'not confirmed', :notice, deactivation_cancelled: true

      context 'confirmed' do
        let!(:model) do
          EquipmentModelMock.new(traits: %i[findable with_category])
        end
        before do
          request.env['HTTP_REFERER'] = 'where_i_came_from'
          put :deactivate,
              params: { id: model.id, deactivation_confirmed: true }
        end
        it { is_expected.to set_flash[:notice] }
        it { is_expected.to redirect_to('where_i_came_from') }
        it 'deactivates model' do
          expect(model).to have_received(:destroy)
        end
      end

      context 'with reservations' do
        it "archives the model's reservations on deactivation" do
          model = EquipmentModelMock.new(traits: %i[findable with_category])
          res = ReservationMock.new
          # stub out scope chain -- SMELL
          allow(Reservation).to receive(:for_eq_model).and_return(Reservation)
          allow(Reservation).to receive(:finalized).and_return([res])
          allow(res).to receive(:archive).and_return(res)
          request.env['HTTP_REFERER'] = 'where_i_came_from'
          put :deactivate,
              params: { id: model.id, deactivation_confirmed: true }
          expect(res).to have_received(:archive)
          expect(res).to have_received(:save).with(validate: false)
        end
      end
    end
    context 'not admin' do
      before do
        mock_user_sign_in
        put :deactivate, params: { id: 1 }
      end
      it_behaves_like 'redirected request'
    end
  end

  describe 'GET show' do
    # the current controller method is too complex to be tested
    # appropriately. FIXME when refactoring the controller
    let!(:model) { FactoryGirl.create(:equipment_model) }
    shared_examples 'GET show success' do |user_role|
      before { mock_user_sign_in(UserMock.new(user_role, requirements: [])) }

      describe 'basic function' do
        before { get :show, params: { id: model } }
        it_behaves_like 'successful request', :show
      end

      it 'sets to correct equipment model' do
        get :show, params: { id: model }
        expect(assigns(:equipment_model)).to eq(model)
      end
      it 'sets @associated_equipment_models' do
        mod1 = FactoryGirl.create(:equipment_model)
        model.associated_equipment_models = [mod1]
        get :show, params: { id: model }
        expect(assigns(:associated_equipment_models)).to eq([mod1])
      end

      it 'limits @associated_equipment_models to maximum 6' do
        model.associated_equipment_models =
          FactoryGirl.create_list(:equipment_model, 7)
        get :show, params: { id: model }
        expect(assigns(:associated_equipment_models).size).to eq(6)
      end
    end
    USER_ROLES.each { |type| it_behaves_like 'GET show success', type }

    context 'with admin user' do
      before do
        FactoryGirl.create_pair(:equipment_item, equipment_model: model)
        sign_in FactoryGirl.create(:admin)
      end
      let!(:missed) do
        FactoryGirl.create(:missed_reservation, equipment_model: model)
      end
      let!(:starts_today) do
        FactoryGirl.create(:reservation, equipment_model: model,
                                         start_date: Time.zone.today,
                                         due_date: Time.zone.today + 2.days)
      end
      let!(:starts_this_week) do
        FactoryGirl.create(:reservation, equipment_model: model,
                                         start_date: Time.zone.today + 2.days,
                                         due_date: Time.zone.today + 4.days)
      end
      let!(:starts_next_week) do
        FactoryGirl.create(:reservation, equipment_model: model,
                                         start_date: Time.zone.today + 9.days,
                                         due_date: Time.zone.today + 11.days)
      end
      it 'includes @pending reservations' do
        get :show, params: { id: model }
        expect(assigns(:pending)).to \
          match_array([starts_today, starts_this_week])
      end
    end
  end
end
