# frozen_string_literal: true
require 'spec_helper'

describe RequirementsController, type: :controller do
  # NOTE: many of these are essentially just testing permissions
  before(:each) { mock_app_config }
  describe 'GET index' do
    context 'is admin' do
      before(:each) do
        allow(Requirement).to receive(:all).and_return(Requirement.none)
        mock_user_sign_in(UserMock.new(:admin))
        get :index
      end
      it_behaves_like 'successful request', :index
      it 'should populate an array of all requirements' do
        expect(Requirement).to have_received(:all).twice
      end
    end
    context 'not an admin' do
      before do
        mock_user_sign_in
        get :index
      end
      it_behaves_like 'redirected request'
    end
  end

  describe 'GET new' do
    context 'is admin' do
      before(:each) do
        allow(Requirement).to receive(:new)
        mock_user_sign_in(UserMock.new(:admin))
        get :new
      end
      it_behaves_like 'successful request', :new
      it 'assigns a new requirement to @requirement' do
        expect(Requirement).to have_received(:new).twice
      end
    end
    context 'not an admin' do
      before do
        mock_user_sign_in
        get :new
      end
      it_behaves_like 'redirected request'
    end
  end

  describe 'POST create' do
    context 'is admin' do
      before(:each) { mock_user_sign_in(UserMock.new(:admin)) }
      context 'successful save' do
        let!(:req) { FactoryGirl.build_stubbed(:requirement) }
        before(:each) do
          allow(Requirement).to receive(:new).and_return(req)
          allow(req).to receive(:save).and_return(true)
          post :create, requirement: { contact_name: 'name' }
        end
        it 'saves a new requirement' do
          expect(Requirement).to have_received(:new).twice
          expect(req).to have_received(:save)
        end
        it { is_expected.to redirect_to(req) }
        it { is_expected.to set_flash }
      end
      context 'with invalid attributes' do
        before(:each) do
          req = RequirementMock.new(save: false)
          allow(Requirement).to receive(:new).and_return(req)
          post :create, requirement: { contact_name: 'name' }
        end
        it { is_expected.not_to set_flash }
        it { is_expected.to render_template(:new) }
      end
    end
    context 'not admin' do
      before do
        mock_user_sign_in
        post :create, requirement: { contact_name: 'name' }
      end
      it_behaves_like 'redirected request'
    end
  end

  describe 'PUT update' do
    context 'is admin' do
      before(:each) { mock_user_sign_in(UserMock.new(:admin)) }
      context 'with valid attributes' do
        let!(:req) { FactoryGirl.build_stubbed(:requirement) }
        before(:each) do
          allow(Requirement).to receive(:find).with(req.id.to_s).and_return(req)
          allow(req).to receive(:update_attributes).and_return(true)
          put :update, id: req.id, requirement: { contact_name: 'Name' }
        end
        it 'should update the attributes of @requirement' do
          expect(req).to have_received(:update_attributes)
        end
        it { is_expected.to redirect_to(req) }
        it { is_expected.to set_flash }
      end
      context 'with invalid attributes' do
        let!(:req) { RequirementMock.new(traits: [:findable]) }
        before(:each) do
          allow(req).to receive(:update_attributes).and_return(false)
          put :update, id: req.id, requirement: { contact_name: 'Name' }
        end
        it { is_expected.to render_template(:edit) }
        it { is_expected.not_to set_flash }
      end
    end
    context 'not admin' do
      before do
        mock_user_sign_in
        put :update, id: 1, requirement: { contact_name: 'Name' }
      end
      it_behaves_like 'redirected request'
    end
  end

  describe 'DELETE destroy' do
    context 'is admin' do
      let!(:req) { RequirementMock.new(traits: [:findable]) }
      before(:each) do
        mock_user_sign_in(UserMock.new(:admin))
        delete :destroy, id: req.id
      end
      it 'destroys the requirement' do
        expect(req).to have_received(:destroy).with(:force)
      end
      it 'should redirect to the requirements index page' do
        expect(response).to redirect_to requirements_url
      end
    end
    context 'not admin' do
      before do
        mock_user_sign_in
        delete :destroy, id: 1
      end
      it_behaves_like 'redirected request'
    end
  end
end
