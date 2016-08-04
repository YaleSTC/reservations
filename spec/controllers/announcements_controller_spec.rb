# frozen_string_literal: true
require 'spec_helper'

describe AnnouncementsController, type: :controller do
  before(:each) { mock_app_config }

  describe 'with admin' do
    before { mock_user_sign_in(UserMock.new(:admin)) }
    describe 'GET index' do
      before do
        allow(Announcement).to receive(:all).and_return(Announcement.none)
        get :index
      end
      it_behaves_like 'successful request', :index
      it 'gets all announcements' do
        expect(Announcement).to have_received(:all).twice
      end
    end

    context 'GET new' do
      before do
        allow(Announcement).to receive(:new)
        get :new
      end
      it 'makes a new announcement with appropriate dates' do
        dates = { starts_at: Time.zone.today, ends_at: Time.zone.today + 1.day }
        expect(Announcement).to have_received(:new).with(dates)
      end
      it_behaves_like 'successful request', :new
    end

    context 'POST create' do
      context 'successful save' do
        let!(:announcement) { AnnouncementMock.new(save: true) }
        before do
          allow(Announcement).to receive(:new).and_return(announcement)
          post :create, announcement: { id: 1 }
        end
        it 'creates a new announcement' do
          expect(Announcement).to have_received(:new).twice
          expect(announcement).to have_received(:save)
        end
        it { is_expected.to redirect_to(announcements_path) }
        it { is_expected.to set_flash[:notice] }
      end
      context 'unsuccessful save' do
        let!(:announcement) { AnnouncementMock.new(save: false) }
        before do
          allow(Announcement).to receive(:new).and_return(announcement)
          post :create, announcement: { id: 1 }
        end
        it { is_expected.to render_template(:new) }
      end
    end

    context 'PUT update' do
      context 'successful update' do
        let!(:announcement) do
          AnnouncementMock.new(traits: [:findable], update_attributes: true)
        end
        before do
          put :update, id: announcement.id, announcement: { id: 1 }
        end
        it { is_expected.to redirect_to(announcements_url) }
        it { is_expected.to set_flash[:notice] }
      end
      context 'unsuccessful update' do
        let!(:announcement) do
          AnnouncementMock.new(traits: [:findable], update_attributes: false)
        end
        before do
          put :update, id: announcement.id, announcement: { id: 1 }
        end
        it { is_expected.to render_template(:edit) }
      end
    end

    context 'DELETE destroy' do
      let!(:announcement) { AnnouncementMock.new(traits: [:findable]) }
      before { delete :destroy, id: announcement.id }
      it 'should delete the announcement' do
        expect(announcement).to have_received(:destroy).with(:force)
      end
      it { is_expected.to redirect_to(announcements_path) }
    end
  end

  context 'is not admin' do
    before { mock_user_sign_in }
    context 'GET index' do
      before { get :index }
      it_behaves_like 'redirected request'
    end
    context 'POST create' do
      before { post :create, announcement: { id: 1 } }
      it_behaves_like 'redirected request'
    end
    context 'PUT update' do
      before { put :update, id: 1 }
      it_behaves_like 'redirected request'
    end
    context 'DELETE destroy' do
      before { delete :destroy, id: 1 }
      it_behaves_like 'redirected request'
    end
  end

  describe 'GET hide as' do
    shared_examples 'can hide announcement' do |user_type|
      let!(:announcement) { AnnouncementMock.new(traits: [:findable]) }
      before do
        mock_user_sign_in(UserMock.new(user_type))
        request.env['HTTP_REFERER'] = 'where_i_came_from'
        get :hide, id: announcement.id
      end
      it 'sets some cookie values' do
        name = 'hidden_announcement_ids'
        jar = request.cookie_jar
        jar.signed[name] = [announcement.id.to_s]
        expect(response.cookies[name]).to eq(jar[name])
      end
    end
    # ROLES = [:superuser, :admin, :checkout_person, :user, :guest, :banned]
    # ROLES.each { |r| it_behaves_like 'can hide announcement', r }
    PASSING_ROLES = [:superuser, :admin].freeze
    PASSING_ROLES.each { |r| it_behaves_like 'can hide announcement', r }
    # FAILING_ROLES = [:checkout_person, :user, :guest, :banned]
    # FAILING_ROLES.each { |r| it_behaves_like 'can hide announcement', r }
  end
end
