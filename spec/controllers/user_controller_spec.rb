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
  let!(:user) { FactoryGirl.create(:user) }

  context 'with admin user' do
    before do
      @controller.stub(:current_user).and_return(FactoryGirl.create(:admin))
    end
    describe 'GET index' do
      let!(:inactive_user) { FactoryGirl.create(:user, deleted_at: Date.today) }
      let!(:other_user) { FactoryGirl.create(:user) }
      before { get :index }
      it_behaves_like "page success"
      it { should render_template(:index) }
      context 'without show deleted' do
        it 'should assign users to all active users' do
          assigns(:users).include?(other_user).should be_true
          assigns(:users).include?(inactive_user).should be_false
        end
      end
      context 'with show deleted' do
        before { get :index, show_deleted: true }
        it 'should assign users to all users' do
          assigns(:users).include?(inactive_user).should be_true
        end
      end
    end
    describe 'GET show' do
      before { get :show, id: user }
      it_behaves_like "page success"
      it { should render_template(:show) }
    end
    describe 'GET new' do
      before { get :new }
      context 'possible netid not provided' do
        it 'should assign @user to a new user' do
          expect(assigns(:user).attributes).to eq(User.new.attributes)
        end
      end
      context 'possible netid provided' do
        before { get :new, possible_netid: 'csw3' }
        it 'should assign @user to the possible netid' do
          expect(assigns(:user).attributes).to eq(User.new(User.search_ldap('csw3')).attributes)
        end
      end
      it 'should assign @can_edit_login to true' do
        expect(assigns(:can_edit_login)).to be_true
      end
      it_behaves_like 'page success'
      it { should render_template(:new) }
    end
    describe 'POST create' do
      context 'with correct params' do
        before do
          @user_attributes = FactoryGirl.attributes_for(:user)
          post :create, user: @user_attributes
        end
        it 'should save the user' do
          User.find(assigns(:user)).should_not be_nil
        end
      end
      context 'with incorrect params' do
        before do
          @bad_attributes = FactoryGirl.attributes_for(:user, first_name: "")
          post :create, user: @bad_attributes
        end
        it 'should not save the user' do
          expect(assigns(:user).save).to be_false
        end
      end

    end
    describe 'GET edit' do
      before { get :edit, id: FactoryGirl.create(:user) }
      it 'should set @can_edit_login to true' do
        expect(assigns(:can_edit_login)).to be_true
      end
      it_behaves_like 'page success'
      it { should render_template(:edit) }
    end
    describe 'PUT update' do
      context 'with nice params' do
        before do
          @new_attributes = FactoryGirl.attributes_for(:user, first_name: "Lolita")
          put :update, user: @new_attributes, id: user
        end
        it 'should update the user' do
          User.find(user)[:first_name].should eq("Lolita")
        end
        it { should set_the_flash }
      end
      context 'without nice params' do
        before do
          @bad_attributes = FactoryGirl.attributes_for(:user, first_name: "Lolita", last_name: "")
          put :update, user: @bad_attributes, id: user
        end
        it 'should not save' do
          User.find(user)[:first_name].should_not eq("Lolita")
        end
      end
    end
    describe 'DELETE destroy' do
      before do
        delete :destroy, id: FactoryGirl.create(:user)
      end
      it 'should destroy the user' do
        User.where(id: assigns(:user)).should be_empty
      end
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
