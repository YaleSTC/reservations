require 'spec_helper'

shared_examples_for 'page success' do
  it { should respond_with(:success) }
  it { should_not set_the_flash }
end

shared_examples_for 'access denied' do
  it { should redirect_to(root_url) }
  it { should set_the_flash }
end

describe UsersController do
  before(:all) {
    @app_config = FactoryGirl.create(:app_config)
  }
  before {
    @controller.stub(:first_time_user).and_return(:nil)
  }

  context 'with admin user' do
    before do
      @controller.stub(:current_user).and_return(FactoryGirl.create(:admin))
    end
    describe 'GET index' do
      before { get :index }
      it_behaves_like "page success"
      it { should render_template(:index) }
      context 'without show deleted' do
        it 'should assign users to all active users'
      end
      context 'with show deleted' do
        before { get :index, show_deleted: true }
        it 'should assign users to all users'
      end
    end
    describe 'GET show' do
      before { get :show, id: FactoryGirl.create(:user) }
      it_behaves_like "page success"
      it { should render_template(:show) }
    end
    describe 'GET new' do
      before { get :new }
      context 'possible netid not provided'
        it 'should assign @user to a new user'
      context 'possible netid provided' do
        it 'should assign @user to the possible netid'
      end
      it 'should assign @can_edit_login to true'
      it_behaves_like 'page success'
      it { should render_template(:new) }
    end
    describe 'POST create' do
      context 'with correct params' do
        before do
          @user_attributes = FactoryGirl.attributes_for(:user)
          post :create, user: @user_attributes
        end
        it 'should save the user'
        describe 'the user'
          it 'should match the params'
      end
      context 'with incorrect params' do
        before do
          @bad_attributes = FactoryGirl.attributes_for(:user, first_name: "")
          post :create, user: @bad_attributes
        end
        it 'should not save the user'
        it 'should show errors'
      end

    end
    describe 'GET edit' do
      before { get :edit, id: FactoryGirl.create(:user) }
      it 'should set @can_edit_login to true'
      it_behaves_like 'page success'
      it { should render_template(:edit) }
    end
    describe 'PUT update' do
      context 'with nice params' do
        before do
          @new_attributes = FactoryGirl.attributes_for(:user)
          @user = FactoryGirl.create(:user)
          put :update, user: @new_attributes, id: @user
        end
        it 'should not remove login from params'
        it 'should update the user'
        describe 'the new user' do
          it 'should have the correct params'
        end
        it { should set_the_flash }
      end
      context 'without nice params' do
        before do
          @bad_attributes = FactoryGirl.attributes_for(:user)
          put :update, user: @bad_attributes
        end
        it 'should not save'
        it 'should show errors'
      end
    end
    describe 'DELETE destroy' do
      before do
        delete :destroy, id: FactoryGirl.create(:user)
      end
      it 'should destroy the user'
      it { should set_the_flash }
      it { should redirect_to(users_url) }
    end
    describe 'PUT find' do
      # wtf
    end
    describe 'PUT deactivate' do
      #
    end
    describe 'PUT activate' do
      #
    end


  end

end
