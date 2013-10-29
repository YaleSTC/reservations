require 'spec_helper'

describe AnnouncementsController do
  before(:all) do
    @app_config = FactoryGirl.create(:app_config)
  end
  before(:each) do
    @controller.stub(:first_time_user).and_return(nil) # required stub or every test will fail
    @announcement = FactoryGirl.create(:announcement, message: "MyText")
  end
  describe 'GET index' do
    context 'is admin' do
      before(:each) do
        @controller.stub(:current_user).and_return(FactoryGirl.create(:admin))
        get :index
      end
      it { should respond_with(:success) }
      it { should render_template(:index) }
      it { should_not set_the_flash }
      # it 'should populate an array of all announcements' do
      #   expect(assigns(:announcements)).to eq([@announcement])
      # end
    end
    context 'not an admin' do
      it 'should redirect to root url if not an admin' do
        @controller.stub(:current_user).and_return(FactoryGirl.create(:user))
        get :index
        response.should redirect_to(root_url)
      end
    end
  end
  describe 'GET new' do
    context 'is admin' do
      before(:each) do
        @controller.stub(:current_user).and_return(FactoryGirl.create(:admin))
        get :new
      end
      it { should respond_with(:success) }
      it { should render_template(:new) }
      it { should_not set_the_flash }
      it 'assigns a new announcement to @announcement' do
        assigns(:announcement).should be_new_record
        assigns(:announcement).kind_of?(Announcement).should be_true
      end
    end
    context 'not an admin' do
      it 'should redirect to root url if not an admin' do
        @controller.stub(:current_user).and_return(FactoryGirl.create(:user))
        get :new
        response.should redirect_to(root_url)
      end
    end
  end 
    describe 'GET edit' do
    context 'is admin' do
      before(:each) do
        @controller.stub(:current_user).and_return(FactoryGirl.create(:admin))
        get :edit, id: @announcement
      end
      it 'should set @announcement to the selected announcement' do
        expect(assigns(:announcement)).to eq(@announcement)
      end
      it { should respond_with(:success) }
      it { should render_template(:edit) }
      it { should_not set_the_flash }
    end
    context 'not admin' do
      it 'should redirect to root url if not an admin' do
        @controller.stub(:current_user).and_return(FactoryGirl.create(:user))
        get :edit, id: @announcement
        response.should redirect_to(root_url)
      end
    end
  end
  describe 'PUT update' do
    context 'is admin' do
      before(:each) do
        @controller.stub(:current_user).and_return(FactoryGirl.create(:admin))
      end
      context 'with valid attributes' do
        before(:each) do
          put :update, id: @announcement, announcement: FactoryGirl.attributes_for(:announcement, message: "John Doe")
        end
        it 'should set @announcement to the correct announcement' do
          expect(assigns(:announcement)).to eq(@announcement)
        end
        it 'should update the attributes of @announcement' do
          @announcement.reload
          @announcement.message.should == "John Doe"
        end
        it { should redirect_to(announcements_url) }
        it { should set_the_flash }
      end
      context 'with invalid attributes' do
        before(:each) do
          put :update, id: @announcement, announcement: FactoryGirl.attributes_for(:announcement, message: "")
        end
        it 'should not update the attributes of @announcement' do
          @announcement.reload
          @announcement.message.should_not == ""
          @announcement.message.should == "MyText"
        end
        it { should render_template(:edit) }
        it { should_not set_the_flash }
      end
    end
    context 'not admin' do
      it 'should redirect to root url if not an admin' do
        @controller.stub(:current_user).and_return(FactoryGirl.create(:user))
        get :update, id: @announcement, announcement: FactoryGirl.attributes_for(:announcement)
        response.should redirect_to(root_url)
      end
    end
  end
  describe 'POST create' do
    context 'is admin' do
      before(:each) do
        @controller.stub(:current_user).and_return(FactoryGirl.create(:admin))
      end
      context 'with valid attributes' do
        before(:each) do
          post :create, announcement: FactoryGirl.attributes_for(:announcement)
        end
        it 'saves a new announcement' do
          expect{
            post :create, announcement: FactoryGirl.attributes_for(:announcement)
          }.to change(Announcement,:count).by(1)
        end
        it { should redirect_to(announcements_url) }
        it { should set_the_flash }
      end
      context 'with invalid attributes' do
        before(:each) do
          post :create, announcement: FactoryGirl.attributes_for(:announcement, message: nil)
        end
        it 'fails to save a new requirment' do
          expect{
            post :create, announcement: FactoryGirl.attributes_for(:announcement, message: nil)
          }.not_to change(Announcement,:count)
        end
        it { should_not set_the_flash }
        it { should render_template(:new) }
      end
    end
    context 'not admin' do
      it 'should redirect to root url if not an admin' do
        @controller.stub(:current_user).and_return(FactoryGirl.create(:user))
        post :create, announcement: FactoryGirl.attributes_for(:announcement)
        response.should redirect_to(root_url)
      end
    end
  end
  describe 'DELETE destroy' do
    context 'is admin' do
      before(:each) do
        @controller.stub(:current_user).and_return(FactoryGirl.create(:admin))
      end
      it 'assigns the selected announcement to @announcement' do
        delete :destroy, id: @announcement
        expect(assigns(:announcement)).to eq(@announcement)
      end
      it 'removes @announcement from the database' do
        expect{
            delete :destroy, id: @announcement
          }.to change(Announcement,:count).by(-1)
      end
      it 'should redirect to the announcements index page' do
        delete :destroy, id: @announcement
        response.should redirect_to announcements_url
      end
    end
    context 'not admin' do
      it 'should redirect to root url if not an admin' do
        @controller.stub(:current_user).and_return(FactoryGirl.create(:user))
        delete :destroy, id: @announcement
        response.should redirect_to(root_url)
      end
    end
  end
  after(:all) do
    @app_config.destroy
  end 
end
