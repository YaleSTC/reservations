require 'spec_helper'

# note, these tests are complex in order to test the admin security features
# -- namely, it was necessary to test two contexts for each method: the user
# being an admin, and not.
describe RequirementsController, type: :controller do
  before(:each) do
    mock_app_config
    @requirement = FactoryGirl.create(:requirement, contact_name: 'Adam Bray')
  end
  describe 'GET index' do
    context 'is admin' do
      before(:each) do
        sign_in FactoryGirl.create(:admin)
        get :index
      end
      it { is_expected.to respond_with(:success) }
      it { is_expected.to render_template(:index) }
      it { is_expected.not_to set_flash }
      it 'should populate an array of all requirements' do
        expect(assigns(:requirements)).to eq([@requirement])
      end
    end
    context 'not an admin' do
      it 'should redirect to root url if not an admin' do
        sign_in FactoryGirl.create(:user)
        get :index
        expect(response).to redirect_to(root_url)
      end
    end
  end
  describe 'GET show' do
    context 'is an admin' do
      before(:each) do
        sign_in FactoryGirl.create(:admin)
        get :show, id: @requirement
      end
      it { is_expected.to respond_with(:success) }
      it { is_expected.to render_template(:show) }
      it { is_expected.not_to set_flash }
      it 'should set @requirement to the selected requirement' do
        expect(assigns(:requirement)).to eq(@requirement)
      end
    end
    context 'not an admin' do
      it 'should redirect to root url if not an admin' do
        sign_in FactoryGirl.create(:user)
        get :show, id: @requirement
        expect(response).to redirect_to(root_url)
      end
    end
  end
  describe 'GET new' do
    context 'is admin' do
      before(:each) do
        sign_in FactoryGirl.create(:admin)
        get :new
      end
      it { is_expected.to respond_with(:success) }
      it { is_expected.to render_template(:new) }
      it { is_expected.not_to set_flash }
      it 'assigns a new requirement to @requirement' do
        expect(assigns(:requirement)).to be_new_record
        expect(assigns(:requirement).is_a?(Requirement)).to be_truthy
      end
    end
    context 'not an admin' do
      it 'should redirect to root url if not an admin' do
        sign_in FactoryGirl.create(:user)
        get :new
        expect(response).to redirect_to(root_url)
      end
    end
  end
  describe 'GET edit' do
    context 'is admin' do
      before(:each) do
        sign_in FactoryGirl.create(:admin)
        get :edit, id: @requirement
      end
      it 'should set @requirement to the selected requirement' do
        expect(assigns(:requirement)).to eq(@requirement)
      end
      it { is_expected.to respond_with(:success) }
      it { is_expected.to render_template(:edit) }
      it { is_expected.not_to set_flash }
    end
    context 'not admin' do
      it 'should redirect to root url if not an admin' do
        sign_in FactoryGirl.create(:user)
        get :edit, id: @requirement
        expect(response).to redirect_to(root_url)
      end
    end
  end
  describe 'PUT update' do
    context 'is admin' do
      before(:each) do
        sign_in FactoryGirl.create(:admin)
      end
      context 'with valid attributes' do
        before(:each) do
          put :update,
              id: @requirement,
              requirement: FactoryGirl.attributes_for(:requirement,
                                                      contact_name: 'John Doe')
        end
        it 'should set @requirement to the correct requirement' do
          expect(assigns(:requirement)).to eq(@requirement)
        end
        it 'should update the attributes of @requirement' do
          @requirement.reload
          expect(@requirement.contact_name).to eq('John Doe')
        end
        it { is_expected.to redirect_to(@requirement) }
        it { is_expected.to set_flash }
      end
      context 'with invalid attributes' do
        before(:each) do
          put :update,
              id: @requirement,
              requirement: FactoryGirl.attributes_for(:requirement,
                                                      contact_name: '')
        end
        it 'should not update the attributes of @requirement' do
          @requirement.reload
          expect(@requirement.contact_name).not_to eq('')
          expect(@requirement.contact_name).to eq('Adam Bray')
        end
        it { is_expected.to render_template(:edit) }
        it { is_expected.not_to set_flash }
      end
    end
    context 'not admin' do
      it 'should redirect to root url if not an admin' do
        sign_in FactoryGirl.create(:user)
        get :update,
            id: @requirement,
            requirement: FactoryGirl.attributes_for(:requirement)
        expect(response).to redirect_to(root_url)
      end
    end
  end
  describe 'POST create' do
    context 'is admin' do
      before(:each) do
        sign_in FactoryGirl.create(:admin)
      end
      context 'with valid attributes' do
        before(:each) do
          post :create, requirement: FactoryGirl.attributes_for(:requirement)
        end
        it 'saves a new requirement' do
          expect do
            post :create, requirement: FactoryGirl.attributes_for(:requirement)
          end.to change(Requirement, :count).by(1)
        end
        it { is_expected.to redirect_to(Requirement.last) }
        it { is_expected.to set_flash }
      end
      context 'with invalid attributes' do
        before(:each) do
          post :create,
               requirement: FactoryGirl.attributes_for(:requirement,
                                                       contact_name: nil)
        end
        it 'fails to save a new requirment' do
          expect do
            post :create,
                 requirement: FactoryGirl.attributes_for(:requirement,
                                                         contact_name: nil)
          end.not_to change(Requirement, :count)
        end
        it { is_expected.not_to set_flash }
        it { is_expected.to render_template(:new) }
      end
    end
    context 'not admin' do
      it 'should redirect to root url if not an admin' do
        sign_in FactoryGirl.create(:user)
        post :create, requirement: FactoryGirl.attributes_for(:requirement)
        expect(response).to redirect_to(root_url)
      end
    end
  end
  describe 'DELETE destroy' do
    context 'is admin' do
      before(:each) do
        sign_in FactoryGirl.create(:admin)
      end
      it 'assigns the selected requirement to @requirement' do
        delete :destroy, id: @requirement
        expect(assigns(:requirement)).to eq(@requirement)
      end
      it 'removes @requirement from the database' do
        expect do
          delete :destroy, id: @requirement
        end.to change(Requirement, :count).by(-1)
      end
      it 'should redirect to the requirements index page' do
        delete :destroy, id: @requirement
        expect(response).to redirect_to requirements_url
      end
    end
    context 'not admin' do
      it 'should redirect to root url if not an admin' do
        sign_in FactoryGirl.create(:user)
        delete :destroy, id: @requirement
        expect(response).to redirect_to(root_url)
      end
    end
  end
end
