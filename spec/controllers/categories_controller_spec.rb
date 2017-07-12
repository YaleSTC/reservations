# frozen_string_literal: true

require 'spec_helper'

describe CategoriesController, type: :controller do
  before(:each) { mock_app_config }

  it_behaves_like 'calendarable', Category

  describe 'GET index' do
    context 'user is admin' do
      before do
        mock_user_sign_in(UserMock.new(:admin))
        get :index
      end
      it_behaves_like 'successful request', :index
      it 'populates an array of active categories' do
        allow(Category).to receive(:active)
        get :index
        expect(Category).to have_received(:active)
      end
      context 'show_deleted' do
        it 'populates an array of all categories' do
          allow(Category).to receive(:all)
          get :index, params: { show_deleted: true }
          expect(Category).to have_received(:all)
        end
      end
    end
    context 'user is not admin' do
      before do
        mock_user_sign_in
        get :index
      end
      it_behaves_like 'redirected request'
    end
  end

  describe 'GET show' do
    context 'user is admin' do
      # NOTE: this may be a superfluous test; #show doesn't do much
      let!(:cat) { CategoryMock.new(traits: [:findable]) }
      before do
        mock_user_sign_in(UserMock.new(:admin))
        get :show, params: { id: cat.id }
      end
      it_behaves_like 'successful request', :show
      it 'sets category to the selected category' do
        get :show, params: { id: cat.id }
        expect(Category).to have_received(:find).with(cat.id.to_s)
                                                .at_least(:once)
      end
    end
    context 'user is not admin' do
      before do
        mock_user_sign_in
        get :show, params: { id: 1 }
      end
      it_behaves_like 'redirected request'
    end
  end

  describe 'GET new' do
    context 'user is admin' do
      before do
        mock_user_sign_in(UserMock.new(:admin))
        get :new
      end
      it_behaves_like 'successful request', :new
      it 'assigns a new category to @category' do
        expect(assigns(:category)).to be_new_record
        expect(assigns(:category).is_a?(Category)).to be_truthy
      end
    end
    context 'user is not admin' do
      before do
        mock_user_sign_in
        get :new
      end
      it_behaves_like 'redirected request'
    end
  end

  describe 'POST create' do
    context 'user is admin' do
      before { mock_user_sign_in(UserMock.new(:admin)) }
      context 'successful save' do
        let!(:cat) { FactoryGirl.build_stubbed(:category) }
        before do
          allow(Category).to receive(:new).and_return(cat)
          allow(cat).to receive(:save).and_return(true)
          post :create, params: { category: { name: 'Name' } }
        end
        it { is_expected.to set_flash[:notice] }
        it { is_expected.to redirect_to(cat) }
      end
      context 'unsuccessful save' do
        let!(:cat) { CategoryMock.new }
        before do
          allow(Category).to receive(:new).and_return(cat)
          allow(cat).to receive(:save).and_return(false)
          post :create, params: { category: { name: 'Name' } }
        end
        it { is_expected.to set_flash[:error] }
        it { is_expected.to render_template(:new) }
      end
    end
    context 'user is not admin' do
      before do
        mock_user_sign_in
        post :create, params: { category: { name: 'Name' } }
      end
      it_behaves_like 'redirected request'
    end
  end

  describe 'PUT update' do
    context 'is admin' do
      before { mock_user_sign_in(UserMock.new(:admin)) }
      context 'successful update' do
        let!(:cat) { FactoryGirl.build_stubbed(:category) }
        before do
          allow(Category).to receive(:find).with(cat.id.to_s).and_return(cat)
          allow(cat).to receive(:update_attributes).and_return(true)
          attributes_hash = { id: 2 }
          put :update, params: { id: cat.id, category: attributes_hash }
        end
        it { is_expected.to set_flash[:notice] }
        it { is_expected.to redirect_to(cat) }
      end
      context 'unsuccessful update' do
        let!(:cat) { CategoryMock.new(traits: [:findable]) }
        before do
          allow(cat).to receive(:update_attributes).and_return(false)
          put :update, params: { id: cat.id, category: { id: 2 } }
        end
        it { is_expected.to render_template(:edit) }
      end
    end
    context 'user is not admin' do
      before do
        mock_user_sign_in
        put :update, params: { id: 1, category: { id: 2 } }
      end
      it_behaves_like 'redirected request'
    end
  end

  describe 'PUT deactivate' do
    context 'is admin' do
      before { mock_user_sign_in(UserMock.new(:admin)) }
      shared_examples 'not confirmed' do |flash_type, **opts|
        let!(:cat) { FactoryGirl.build_stubbed(:category) }
        before do
          allow(Category).to receive(:find).with(cat.id.to_s).and_return(cat)
          allow(cat).to receive(:destroy)
          put :deactivate, params: { id: cat.id, **opts }
        end
        it { is_expected.to set_flash[flash_type] }
        it { is_expected.to redirect_to(cat) }
        it "doesn't destroy the category" do
          expect(cat).not_to have_received(:destroy)
        end
      end
      it_behaves_like 'not confirmed', :notice, deactivation_cancelled: true
      it_behaves_like 'not confirmed', :error

      context 'confirmed' do
        let!(:cat) do
          CategoryMock.new(traits: [:findable], equipment_models: [])
        end
        before do
          request.env['HTTP_REFERER'] = 'where_i_came_from'
          put :deactivate, params: { id: cat.id, deactivation_confirmed: true }
        end
        it 'destroys the category' do
          expect(cat).to have_received(:destroy)
        end
      end

      context 'with reservations' do
        let!(:cat) { CategoryMock.new(traits: [:findable]) }
        let!(:res) { instance_spy('reservation') }
        before do
          model = EquipmentModelMock.new(traits: [[:with_category, cat: cat]])
          # stub out scope chain -- SMELL
          allow(Reservation).to receive(:for_eq_model).with(model.id)
                                                      .and_return(Reservation)
          allow(Reservation).to receive(:finalized).and_return([res])
          request.env['HTTP_REFERER'] = 'where_i_came_from'
          put :deactivate, params: { id: cat.id, deactivation_confirmed: true }
        end
        it 'archives the reservation' do
          expect(res).to have_received(:archive)
        end
      end
    end
    context 'user is not admin' do
      before do
        mock_user_sign_in
        put :deactivate, params: { id: 1 }
      end
      it_behaves_like 'redirected request'
    end
  end
end
