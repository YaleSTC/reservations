# frozen_string_literal: true
require 'spec_helper'

describe UsersController, type: :controller do
  before(:each) { mock_app_config }

  it_behaves_like 'calendarable', User

  describe 'GET index' do
    before { mock_user_sign_in(UserMock.new(:admin)) }
    context 'basic function' do
      before { get :index }
      it_behaves_like 'successful request', :index
    end
    it 'defaults to active users' do
      allow(User).to receive(:active).and_return(User.none)
      get :index
      expect(User).to have_received(:active)
    end

    it 'orders users by username' do
      allow(User).to receive(:active).and_return(User)
      allow(User).to receive(:order)
      get :index
      expect(User).to have_received(:order).with('username ASC')
    end

    context 'with show banned' do
      it 'should assign users to all users' do
        allow(User).to receive(:active)
        get :index, show_banned: true
        expect(User).not_to have_received(:active)
      end
    end
  end

  describe 'GET show' do
    before { mock_user_sign_in(UserMock.new(:admin)) }
    let!(:user) do
      UserMock.new(traits: [:findable], reservations: spy('Array'))
    end
    context 'basic function' do
      before { get :show, id: user.id }
      it_behaves_like 'successful request', :show
    end
    it "gets the user's reservations" do
      get :show, id: user.id
      expect(user).to have_received(:reservations)
    end

    # TODO: tests on the reservations being filtered?

    context 'with banned user' do
      before do
        banned = UserMock.new(:banned, traits: [:findable],
                                       reservations: spy('Array'))
        get :show, id: banned.id
      end
      it { is_expected.to respond_with(:success) }
      it { is_expected.to set_flash[:error] }
    end
  end

  describe 'POST quick_new' do
    before { mock_user_sign_in(UserMock.new(:admin)) }
    it 'gets the username from ldap' do
      allow(User).to receive(:search)
      post :quick_new, format: :js, possible_netid: 'csw3'
      expect(User).to have_received(:search)
    end
    it 'attempts to make a new user from the ldap result' do
      netid = 'sky3'
      allow(User).to receive(:search).and_return(netid)
      allow(User).to receive(:new)
      post :quick_new, format: :js, possible_netid: netid
      expect(User).to have_received(:new).with(netid)
    end
  end

  describe 'POST quick_create' do
    before { mock_user_sign_in(UserMock.new(:admin)) }
    it 'creates a new user from the params' do
      user_params = { username: 'sky3' }
      allow(User).to receive(:new).and_return(UserMock.new)
      post :quick_create, format: :js, user: user_params
      expect(User).to have_received(:new).with(user_params)
    end
    it 'sets the role to normal if not given' do
      user = UserMock.new
      user_params = { username: 'sky3' }
      allow(User).to receive(:new).and_return(user)
      post :quick_create, format: :js, user: user_params
      expect(user).to have_received(:role=).with('normal')
    end
    it 'sets the view mode to the role' do
      user = UserMock.new(role: 'role')
      user_params = { username: 'sky3' }
      allow(User).to receive(:new).and_return(user)
      post :quick_create, format: :js, user: user_params
      expect(user).to have_received(:view_mode=).with('role')
    end
    context 'using CAS' do
      around(:example) do |example|
        env_wrapper('CAS_AUTH' => '1') { example.run }
      end
      it 'sets the cas login to the username param' do
        user = UserMock.new
        user_params = { username: 'sky3' }
        allow(User).to receive(:new).and_return(user)
        post :quick_create, format: :js, user: user_params
        expect(user).to have_received(:cas_login=).with('sky3')
      end
    end
    context 'successful save' do
      let!(:user) { UserMock.new(save: true, id: 1) }
      before do
        user_params = { username: 'sky3' }
        allow(User).to receive(:new).and_return(user)
        post :quick_create, format: :js, user: user_params
      end
      it "sets the cart's user to the new user" do
        expect(session[:cart].reserver_id).to eq(user.id)
      end
      it { is_expected.to set_flash[:notice] }
      # TODO: render action test?
    end
    context 'unsuccessful save' do
      # TODO: render action test?
    end
  end

  describe 'GET new' do
    context 'using CAS' do
      around(:example) do |example|
        env_wrapper('CAS_AUTH' => '1') { example.run }
      end
      context 'with current user' do
        before { mock_user_sign_in(UserMock.new(:admin)) }
        it 'initializes a new user' do
          allow(User).to receive(:new)
          get :new
          expect(User).to have_received(:new).at_least(:once)
        end
      end
    end
    context 'without CAS' do
      it 'initializes a new user' do
        mock_user_sign_in(UserMock.new(:admin))
        allow(User).to receive(:new)
        get :new
        expect(User).to have_received(:new).at_least(:once)
      end
    end
  end

  describe 'POST create' do
    before { mock_user_sign_in(UserMock.new(:admin)) }
    it 'initializes a new user from the params' do
      user_params = { username: 'sky3' }
      allow(User).to receive(:new).and_return(UserMock.new)
      post :create, user: user_params
      expect(User).to have_received(:new).with(user_params).at_least(:once)
    end
    it 'sets the role to normal if not given' do
      user = UserMock.new
      user_params = { username: 'sky3' }
      allow(User).to receive(:new).and_return(user)
      post :create, user: user_params
      expect(user).to have_received(:role=).with('normal')
    end
    it 'sets the view mode to the role' do
      user = UserMock.new(role: 'role')
      user_params = { username: 'sky3' }
      allow(User).to receive(:new).and_return(user)
      post :create, user: user_params
      expect(user).to have_received(:view_mode=).with('role')
    end
    context 'using CAS' do
      around(:example) do |example|
        env_wrapper('CAS_AUTH' => '1') { example.run }
      end
      it 'sets the cas login from params' do
        user = UserMock.new
        user_params = { username: 'sky3' }
        allow(User).to receive(:new).and_return(user)
        post :create, user: user_params
        expect(user).to have_received(:cas_login=).with('sky3')
      end
    end
    context 'without CAS' do
      before { mock_user_sign_in(UserMock.new(:admin)) }
      it 'sets the username to the email' do
        user = UserMock.new(email: 'email')
        allow(User).to receive(:new).and_return(user)
        post :create, user: { first_name: 'name' }
        expect(user).to have_received(:username=).with('email')
      end
    end
    context 'successful save' do
      before { mock_user_sign_in(UserMock.new(:admin)) }
      let!(:user) { FactoryGirl.build_stubbed(:user) }
      before do
        allow(User).to receive(:new).and_return(user)
        allow(user).to receive(:save).and_return(true)
        post :create, user: { first_name: 'name' }
      end
      it { is_expected.to set_flash[:notice] }
      it { is_expected.to redirect_to(user) }
    end
    context 'unsuccessful save' do
      before { mock_user_sign_in(UserMock.new(:admin)) }
      let!(:user) { UserMock.new(save: false) }
      before do
        allow(User).to receive(:new).and_return(user)
        post :create, user: { first_name: 'name' }
      end
      it { is_expected.to render_template(:new) }
    end
  end

  describe 'PUT ban' do
    before { mock_user_sign_in(UserMock.new(:admin)) }
    before { request.env['HTTP_REFERER'] = 'where_i_came_from' }
    context 'guest user' do
      before do
        user = UserMock.new(:guest, traits: [:findable])
        put :ban, id: user.id
      end
      it_behaves_like 'redirected request'
    end
    context 'user is self' do
      before do
        user = UserMock.new(:admin, traits: [:findable])
        mock_user_sign_in user
        put :ban, id: user.id
      end
      it_behaves_like 'redirected request'
    end
    context 'able to ban' do
      let!(:user) { UserMock.new(traits: [:findable]) }
      before { put :ban, id: user.id }
      it_behaves_like 'redirected request'
      it 'should make the user banned' do
        expect(user).to have_received(:update_attributes)
          .with(hash_including(role: 'banned', view_mode: 'banned'))
      end
    end
  end

  describe 'PUT unban' do
    before { mock_user_sign_in(UserMock.new(:admin)) }
    before { request.env['HTTP_REFERER'] = 'where_i_came_from' }
    context 'guest user' do
      before do
        user = UserMock.new(:guest, traits: [:findable])
        put :unban, id: user.id
      end
      it_behaves_like 'redirected request'
    end
    context 'able to unban' do
      let!(:user) { UserMock.new(:banned, traits: [:findable]) }
      before { put :unban, id: user.id }
      it_behaves_like 'redirected request'
      it 'should make the user banned' do
        expect(user).to have_received(:update_attributes)
          .with(hash_including(role: 'normal', view_mode: 'normal'))
      end
    end
  end

  describe 'PUT find' do
    before { mock_user_sign_in(UserMock.new(:admin)) }
    context 'no fake searched id' do
      before do
        request.env['HTTP_REFERER'] = 'where_i_came_from'
        put :find, fake_searched_id: ''
      end
      it { is_expected.to set_flash[:alert] }
      it_behaves_like 'redirected request'
    end
    context 'no searched id' do
      context 'user found' do
        let!(:username) { 'sky3' }
        let!(:user) { FactoryGirl.build_stubbed(:user, username: username) }
        before do
          allow_any_instance_of(described_class).to \
            receive(:get_autocomplete_items).with(term: username)
            .and_return([user])
          put :find, fake_searched_id: username, searched_id: ''
        end
        it 'redirects to found user' do
          expect(response).to \
            redirect_to(manage_reservations_for_user_path(user.id))
        end
      end
      context 'user not found' do
        before do
          request.env['HTTP_REFERER'] = 'where_i_came_from'
          put :find, fake_searched_id: 'sky3', searched_id: ''
        end
        it { is_expected.to set_flash[:alert] }
        it_behaves_like 'redirected request'
      end
    end
    context 'with searched id' do
      let!(:username) { 'sky3' }
      let!(:user) { FactoryGirl.build_stubbed(:user, username: username) }
      before do
        allow(User).to receive(:find).with(user.id.to_s).and_return(user)
        put :find, fake_searched_id: username, searched_id: user.id
      end
      it 'redirects to found user' do
        expect(response).to \
          redirect_to(manage_reservations_for_user_path(user.id))
      end
    end
  end
end
