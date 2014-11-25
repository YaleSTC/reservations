require 'spec_helper'

shared_examples_for 'page success' do
  it { is_expected.to respond_with(:success) }
  it { is_expected.not_to set_the_flash }
end

shared_examples_for 'access denied' do
  it { is_expected.to redirect_to(root_url) }
  it { is_expected.to set_the_flash }
end

describe AnnouncementsController, :type => :controller do
  before(:all) {
    @app_config = FactoryGirl.create(:app_config)
  }

 describe 'with admin' do
    before do
      sign_in FactoryGirl.create(:admin)
    end
    context 'GET index' do
      before do
        get:index
      end
      it_behaves_like 'page success'
      it { is_expected.to render_template(:index) }
      it 'should assign @announcements to all Announcements' do
        expect(assigns(:announcements)).to eq(Announcement.all)
      end
    end
    context 'GET new' do
      before do
        get :new
      end
      it 'sets the default announcement' do
        expect(assigns(:announcement)[:starts_at]).to eq(Time.current.midnight)
        expect(assigns(:announcement)[:ends_at]).to eq(Time.current.midnight + 24.hours)
      end
      it_behaves_like 'page success'
      it { is_expected.to render_template(:new) }
    end
    context 'GET edit' do
      before do
        get :edit, id: FactoryGirl.create(:announcement)
      end
      it_behaves_like 'page success'
      it { is_expected.to render_template(:edit) }
    end
    context 'POST create' do
      context 'with correct params' do
        before do
          @attributes = FactoryGirl.attributes_for(:announcement)
          post :create, announcement: @attributes
        end
        it 'should create the new announcement' do
          expect(Announcement.find(assigns(:announcement))).not_to be_nil
        end
        it 'should pass the correct params' do
          expect(assigns(:announcement)[:starts_at].to_date).to eq(@attributes[:starts_at].to_date)
          expect(assigns(:announcement)[:ends_at].to_date).to eq(@attributes[:ends_at].to_date)
        end
        it { is_expected.to redirect_to(announcements_path) }
        it { is_expected.to set_the_flash }
      end
      context 'with incorrect params' do
        before do
          @attributes = FactoryGirl.attributes_for(:announcement)
          @attributes[:ends_at] = Date.yesterday
          post :create, announcement: @attributes
        end
        it { is_expected.to render_template(:new) }
      end
    end
    context 'PUT update' do
      before do
        @new_attributes = FactoryGirl.attributes_for(:announcement)
        @new_attributes[:message] = "New Message!!"
        put :update, id: FactoryGirl.create(:announcement), announcement: @new_attributes
      end
      it 'updates the announcement' do
        expect(assigns(:announcement)[:message]).to eq(@new_attributes[:message])
      end
    end
    context 'DELETE destroy' do
      before do
        delete :destroy, id: FactoryGirl.create(:announcement)
      end
      it 'should delete the announcement' do
        expect(Announcement.where(id:  assigns(:announcement)[:id])).to be_empty
      end
      it { is_expected.to redirect_to(announcements_path) }
    end
  end
  context 'is not admin' do
    before do
      sign_in FactoryGirl.create(:user)
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
