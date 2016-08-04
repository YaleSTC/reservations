# frozen_string_literal: true
require 'spec_helper'

describe CatalogController, type: :controller do
  let!(:user) { UserMock.new(traits: [:findable]) }
  let!(:cart) { CartMock.new(reserver_id: user.id, items: {}) }
  before(:each) do
    mock_app_config
    mock_user_sign_in(user)
    allow_any_instance_of(described_class).to receive(:fix_cart_date)
    allow_any_instance_of(ApplicationController).to receive(:fix_cart_date)
    allow_any_instance_of(described_class).to \
      receive(:prepare_catalog_index_vars)
    allow_any_instance_of(described_class).to receive(:cart).and_return(cart)
  end

  describe 'GET index' do
    before(:each) { get :index, {}, cart: cart }
    it 'gets the reserver id' do
      expect(cart).to have_received(:reserver_id).at_least(:once)
    end
    it_behaves_like 'successful request', :index
  end

  describe 'PUT add_to_cart' do
    context 'valid equipment_model selected' do
      let!(:eq_model) { EquipmentModelMock.new(traits: [:findable]) }
      before do
        allow(cart).to receive(:validate_all).and_return([])
        put :add_to_cart, { id: eq_model.id }, cart: cart
      end
      it 'calls cart.add_item to add item to cart' do
        expect(cart).to have_received(:add_item).with(eq_model, any_args)
      end
      it 'should set flash[:error] if errors exist' do
        allow(cart).to receive(:validate_all).and_return(['ERROR'])
        put :add_to_cart, id: eq_model.id
        expect(flash[:error]).not_to be_nil
      end
      it { is_expected.to set_flash[:notice] }
      it { is_expected.to redirect_to(root_path) }
    end
    context 'no equipment_model selected' do
      before(:each) do
        allow(Rails.logger).to receive(:error)
        put :add_to_cart, { id: 1 }, cart: cart
      end
      it 'should add logger error' do
        expect(Rails.logger).to have_received(:error)
          .with('Attempt to add invalid equipment model 1')
      end
      it_behaves_like 'redirected request'
    end
  end

  describe 'POST submit_cart_updates_form on item' do
    let!(:eq_model) { EquipmentModelMock.new(traits: [:findable]) }
    let!(:attrs) { { id: eq_model.id, quantity: 2, reserver_id: user.id } }
    it 'adjusts item quantity with cart#edit_cart_item' do
      post :submit_cart_updates_form, attrs, cart: cart
      expect(cart).to have_received(:edit_cart_item).with(eq_model, 2)
    end
    context 'newly empty cart' do
      before do
        allow(cart).to receive(:items).and_return(spy('Array', empty?: true))
        post :submit_cart_updates_form, attrs, cart: cart
      end
      it { is_expected.to redirect_to(root_path) }
    end
    context 'non empty cart' do
      before do
        allow(cart).to receive(:items).and_return(spy('Array', empty?: false))
        post :submit_cart_updates_form, attrs, cart: cart
      end
      it { is_expected.to redirect_to(new_reservation_path) }
    end
  end

  describe 'PUT changing dates on confirm reservation page' do
    # TODO: refactor update_cart so we can actually check that dates are
    # being set
    it 'calls update_cart' do
      tomorrow = Time.zone.today + 1.day
      params = { cart: { start_date_cart: tomorrow.strftime('%Y-%m-%d'),
                         due_date_cart:
                         (tomorrow + 1.day).strftime('%Y-%m-%d') },
                 reserver_id: user.id }
      expect_any_instance_of(described_class).to receive(:update_cart)
      post :change_reservation_dates, params, cart: cart
    end
  end

  describe 'PUT update_user_per_cat_page' do
    before(:each) { put :update_user_per_cat_page, {}, cart: cart }
    it { is_expected.to redirect_to(root_path) }
  end

  describe 'PUT search' do
    context 'query is blank' do
      before(:each) { put :search, { query: '' }, cart: cart }
      it { is_expected.to redirect_to(root_path) }
    end
    context 'query is not blank' do
      it 'calls catalog_search on EquipmentModel' do
        expect(EquipmentModel).to \
          receive_message_chain(:active, :catalog_search)
        put :search, { query: 'query' }, cart: cart
      end
      it 'calls catalog_search on EquipmentItem' do
        allow(EquipmentItem).to receive(:catalog_search)
        put :search, { query: 'query' }, cart: cart
        expect(EquipmentItem).to have_received(:catalog_search).with('query')
      end
      it 'calls catalog_search on Category' do
        allow(Category).to receive(:catalog_search)
        put :search, { query: 'query' }, cart: cart
        expect(Category).to have_received(:catalog_search).with('query')
      end
    end
  end
end
