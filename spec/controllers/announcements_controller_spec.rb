require 'spec_helper'

shared_examples_for 'page success' do
  it { should respond_with(:success) }
  it { should_not set_the_flash }
end

shared_examples_for 'access denied' do
  it { should redirect_to(root_url) }
  it { should set_the_flash }
end

describe AnnouncementsController do
  before(:all) {
    @app_config = FactoryGirl.create(:app_config)
  }
  before {
    @controller.stub(:first_time_user).and_return(:nil)
  }

 describe 'with admin' do
    before do
      @controller.stub(:current_user).and_return(FactoryGirl.create(:admin))
    end
    context 'GET index' do
      before do
        get:index
      end
      it_behaves_like 'page success'
      it { should render_template(:index) }
      it 'should assign @announcements to all Announcements' do
        expect(assigns(:announcements)).to eq(Announcement.all)
      end
    end
    context 'GET new' do
      before do
        get :new
      end
      it 'sets the default announcement' do
        assigns(:announcement)[:starts_at].should eq(Date::today.to_time)
        assigns(:announcement)[:ends_at].should eq(Date::tomorrow.to_time)
      end
      it_behaves_like 'page success'
      it { should render_template(:new) }
    end
    context 'GET edit' do
      before do
        get :edit, id: FactoryGirl.create(:announcement)
      end
      it_behaves_like 'page success'
      it { should render_template(:edit) }
    end
    context 'POST create' do
      context 'with correct params' do
        before do
          @attributes = FactoryGirl.attributes_for(:announcement)
          post :create, announcement: @attributes
        end
        it 'should create the new announcement' do
          Announcement.find(assigns(:announcement)).should_not be_nil
        end
        it 'should pass the correct params' do
          assigns(:announcement)[:starts_at].to_date.should eq(@attributes[:starts_at].to_date)
          assigns(:announcement)[:ends_at].to_date.should eq(@attributes[:ends_at].to_date)
        end
        it { should redirect_to(announcements_path) }
        it { should set_the_flash }
      end
      context 'with incorrect params' do
        before do
          @attributes = FactoryGirl.attributes_for(:announcement)
          @attributes[:ends_at] = Date.yesterday
          post :create, announcement: @attributes
        end
        it { should render_template(:new) }
      end
    end
    context 'PUT update' do
      before do
        @new_attributes = FactoryGirl.attributes_for(:announcement)
        @new_attributes[:message] = "New Message!!"
        put :update, id: FactoryGirl.create(:announcement), announcement: @new_attributes
      end
      it 'updates the announcement' do
        assigns(:announcement)[:message].should eq(@new_attributes[:message])
      end
    end
    context 'DELETE destroy' do
      before do
        delete :destroy, id: FactoryGirl.create(:announcement)
      end
      it 'should delete the announcement' do
        Announcement.where(id:  assigns(:announcement)[:id]).should be_empty
      end
      it { should redirect_to(announcements_path) }
    end
  end
  context 'is not admin' do
    before do
      @controller.stub(:current_user).and_return(FactoryGirl.create(:user))
      @announcement = FactoryGirl.create(:announcement)
      @attributes = FactoryGirl.attributes_for(:announcement)
    end

    context 'GET index' do
      before do
        get :index
      end 
      it_behaves_like 'access denied'
    end
    context 'POST create' do
      before do
        post :create, announcement: @attributes
      end
      it_behaves_like 'access denied'
    end
    context 'PUT update' do
      before do
        put :update, id: @announcement
      end
      it_behaves_like 'access denied'
    end
    context 'DELETE destroy' do
      before do
        delete :destroy, id: @announcement
      end
      it_behaves_like 'access denied'
    end
  end
end
