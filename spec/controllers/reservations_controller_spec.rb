# frozen_string_literal: true
require 'spec_helper'
require 'helpers/email_helper_spec'

describe ReservationsController, type: :controller do
  AC_DEFAULTS = { disable_user_emails: false,
                  override_on_create: false,
                  override_at_checkout: false,
                  res_exp_time: false,
                  admin_email: 'admin@email.com' }.freeze

  before(:each) { mock_app_config(AC_DEFAULTS) }

  shared_examples 'inaccessible by banned user' do
    before { mock_user_sign_in(FactoryGirl.build_stubbed(:banned)) }
    it_behaves_like 'redirected request'
  end

  describe '#update_index_dates (PUT)' do
    before(:each) do
      mock_user_sign_in
      list = { start_date: Time.zone.today.to_s,
               end_date: (Time.zone.today + 1.day).to_s,
               filter: :reserved }
      put :update_index_dates, list: list
    end
    it { is_expected.to redirect_to('/reservations') }
    it 'disables all_date viewing' do
      expect(session[:all_dates]).to be_falsey
    end
    it 'sets the session dates' do
      expect(session[:index_start_date]).to eq(Time.zone.today)
      expect(session[:index_end_date]).to eq(Time.zone.today + 1.day)
    end
    it 'sets the session filter' do
      expect(session[:filter]).to eq(:reserved)
    end
  end

  describe '#view_all_dates (PUT)' do
    before do
      mock_user_sign_in
      put :view_all_dates
    end
    it { is_expected.to redirect_to('/reservations') }
    it 'enables all_date viewing' do
      expect(session[:all_dates]).to be_truthy
    end
  end

  describe '#index (GET /reservations/)' do
    # SMELLS:
    #   - @filters
    #   - long method
    #   - message chains
    let!(:time_filtered) { spy('Array') }

    shared_examples 'filterable' do
      it 'can filter' do
        trait = :checked_out
        get :index, trait => true
        expect(time_filtered).to have_received(trait).at_least(:once)
      end
      it 'with respect to session[:filter] first' do
        trait = :checked_out
        session_trait = :returned
        session[:filter] = session_trait
        get :index, trait => true
        expect(time_filtered).to have_received(session_trait).at_least(:once)
        expect(time_filtered).to have_received(trait).at_least(:once)
      end
    end

    context 'normal user' do
      let!(:user) do
        res = spy('Array', starts_on_days: time_filtered)
        UserMock.new(reservations: res)
      end
      before(:each) do
        mock_user_sign_in(user)
        allow(Reservation).to receive(:starts_on_days)
        get :index
      end
      it { is_expected.to respond_with(:success) }
      it { is_expected.to render_template(:index) }
      it "only gets the current user's reservations" do
        expect(Reservation).not_to have_received(:starts_on_days)
        expect(user).to have_received(:reservations).at_least(:once)
      end
      it 'defaults to reserved' do
        # twice: once from set_counts, once from filtering
        expect(time_filtered).to have_received(:reserved).twice
      end
      it_behaves_like 'filterable'
    end

    context 'admin' do
      let!(:user) { UserMock.new(:admin) }
      before(:each) do
        allow(Reservation).to receive(:starts_on_days)
          .and_return(time_filtered)
        mock_user_sign_in(user)
        get :index
      end
      it 'gets all reservations' do
        expect(Reservation).to have_received(:starts_on_days)
      end
      it 'defaults to upcoming' do
        # twice: once from set_counts, once from filtering
        expect(time_filtered).to have_received(:upcoming).twice
      end
      it_behaves_like 'filterable'
    end

    it_behaves_like 'inaccessible by banned user' do
      before { get :index }
    end
  end

  describe '#new (GET /reservations/new)' do
    # SMELLS:
    #   - long method
    #   - redirect location set for testing in code ???
    #   - feature envy
    # most of this should probably be in the cart?
    it_behaves_like 'inaccessible by banned user' do
      before { get :new }
    end

    context 'normal user' do
      let!(:user) { FactoryGirl.build_stubbed(:user) }
      before(:each) do
        allow(User).to receive(:find).with(user.id).and_return(user)
        mock_user_sign_in(user)
        request.env['HTTP_REFERER'] = 'where_i_came_from'
      end

      context 'with an empty cart' do
        before(:each) { get :new }
        it { expect(response).to redirect_to('where_i_came_from') }
        it { is_expected.to set_flash }
      end

      context 'with a non-empty cart' do
        let!(:cart) do
          instance_spy('Cart', items: { fake_id: 1 }, reserver_id: user.id,
                               start_date: Time.zone.today,
                               due_date: Time.zone.today - 1.day)
        end
        context 'without errors' do
          before(:each) do
            allow(cart).to receive(:validate_all).and_return('')
            get :new, nil, cart: cart
          end
          it { is_expected.to render_template(:new) }
          it 'initializes a new reservation' do
            allow(Reservation).to receive(:new)
            get :new, nil, cart: cart
            expect(Reservation).to have_received(:new)
          end
          it 'assigns errors' do
            expect(assigns(:errors)).to eq ''
          end
        end
        context 'with errors' do
          before do
            allow(cart).to receive(:validate_all).and_return('error')
            get :new, nil, cart: cart
          end
          it 'assigns errors' do
            expect(assigns(:errors)).to eq 'error'
          end
          it { is_expected.to set_flash[:error] }
        end
      end
    end

    context 'can override errors' do
      let!(:user) { FactoryGirl.build_stubbed(:admin) }
      before(:each) do
        allow(User).to receive(:find).with(user.id).and_return(user)
        mock_user_sign_in(user)
        request.env['HTTP_REFERER'] = 'where_i_came_from'
      end

      context 'with a non-empty cart' do
        before(:each) do
          @cart = FactoryGirl.build(:cart_with_items, reserver_id: user.id)
          get :new, nil, cart: @cart
        end

        it 'should display errors' do
          expect(assigns(:errors)).to eq @cart.validate_all
        end
        it { is_expected.to render_template(:new) }
      end
    end
  end

  describe '#create (POST /reservations/create)' do
    # SMELLS: so, so many of them
    # not going to refactor this yet
    before(:all) do
      @user = FactoryGirl.create(:user)
      @checkout_person = FactoryGirl.create(:checkout_person)
    end
    after(:all) do
      User.destroy_all
    end
    it_behaves_like 'inaccessible by banned user' do
      before do
        post :create,
             reservation: FactoryGirl.attributes_for(:valid_reservation)
      end
    end

    context 'when accessed by non-banned user' do
      before(:each) { sign_in @user }

      context 'with validation-failing items in Cart' do
        before(:each) do
          @invalid_cart =
            FactoryGirl.build(:invalid_cart, reserver_id: @user.id)
          @req = proc do
            post :create,
                 { reservation: { notes: 'because I can' } },
                 cart: @invalid_cart
          end
          @req_no_notes = proc do
            post :create,
                 { reservation: { notes: '' } },
                 cart: @invalid_cart
          end
        end

        context 'no justification provided' do
          before do
            sign_in @checkout_person
            @req_no_notes.call
          end

          it { is_expected.to render_template(:new) }

          it 'should set @notes_required to true' do
            expect(assigns(:notes_required)).to be_truthy
          end
        end

        context 'and user can override errors' do
          before(:each) do
            mock_app_config(AC_DEFAULTS.merge(override_on_create: true))
            sign_in @checkout_person
          end

          it 'affects the database' do
            expect { @req.call }.to change { Reservation.count }
          end

          it 'sets the reservation notes' do
            @req.call
            expect(Reservation.last.notes.empty?).not_to be_truthy
          end

          it 'should redirect' do
            @req.call
            expect(response).to\
              redirect_to(manage_reservations_for_user_path(@user.id))
          end

          it 'sets the flash' do
            @req.call
            expect(flash[:notice]).not_to be_nil
          end
        end

        context 'and user cannot override errors' do
          # request would be filed
          before(:each) do
            mock_app_config(AC_DEFAULTS.merge(override_on_create: false))
            sign_in @checkout_person
          end
          it 'affects database' do
            expect { @req.call }.to change { Reservation.count }
          end

          it 'sets the reservation notes' do
            @req.call
            expect(Reservation.last.notes.empty?).not_to be_truthy
          end

          it 'redirects to catalog_path' do
            @req.call
            expect(response).to redirect_to(catalog_path)
          end

          it 'should not set the flash' do
            @req.call
            expect(flash[:error]).to be_nil
          end
        end
      end

      context 'with validation-passing items in Cart' do
        before(:each) do
          @valid_cart = FactoryGirl.build(:cart_with_items)
          @req = proc do
            post :create,
                 { reservation: { start_date: Time.zone.today,
                                  due_date: (Time.zone.today + 1.day),
                                  reserver_id: @user.id } },
                 cart: @valid_cart
          end
        end

        it 'saves items into database' do
          expect { @req.call }.to change { Reservation.count }
        end

        it 'sets the reservation notes' do
          @req.call
          expect(Reservation.last.notes.empty?).not_to be_truthy
        end

        it 'sets the status to reserved' do
          @req.call
          expect(Reservation.last.reserved?)
        end

        it 'empties the Cart' do
          @req.call
          expect(response.request.env['rack.session'][:cart].items.count)
            .to eq(0)
          # Cart.should_receive(:new)
        end

        it 'sets flash[:notice]' do
          @req.call
          expect(flash[:notice]).not_to be_nil
        end

        it 'is a redirect' do
          @req.call
          expect(response).to be_redirect
        end

        context 'with notify_admin_on_create set' do
          before(:each) do
            ActionMailer::Base.deliveries.clear
            mock_app_config(AC_DEFAULTS.merge(notify_admin_on_create: true))
          end

          it 'cc-s the admin on the confirmation email' do
            @req.call
            delivered = ActionMailer::Base.deliveries.last
            expect(delivered).not_to be_nil
            expect(delivered.subject).to \
              eq('[Reservations] Reservation created')
          end
        end

        context 'without notify_admin_on_create set' do
          before(:each) do
            ActionMailer::Base.deliveries.clear
            mock_app_config(AC_DEFAULTS.merge(notify_admin_on_create: false))
          end

          it 'cc-s the admin on the confirmation email' do
            @req.call
            delivered = ActionMailer::Base.deliveries.last
            expect(delivered).to be_nil
          end
        end
      end

      context 'with banned reserver' do
        before(:each) do
          sign_in @checkout_person
          @valid_cart = FactoryGirl.build(:cart_with_items)
          @banned = FactoryGirl.create(:banned)
          @valid_cart.reserver_id = @banned.id
          @req = proc do
            post :create,
                 { reservation: { start_date: Time.zone.today,
                                  due_date: (Time.zone.today + 1.day),
                                  reserver_id: @banned.id,
                                  notes: 'because I can' } },
                 cart: @valid_cart
          end
        end

        it 'does not save' do
          expect { @req.call }.not_to change { Reservation.count }
        end

        it 'is a redirect' do
          @req.call
          expect(response).to be_redirect
        end

        it 'sets flash[:error]' do
          @req.call
          expect(flash[:error]).not_to be_nil
        end
      end
    end
  end

  describe '#edit (GET /reservations/:id/edit)' do
    # SMELLS:
    #   - message chain
    it_behaves_like 'inaccessible by banned user' do
      before { get 'edit', id: 1 }
    end

    context 'when accessed by patron' do
      before(:each) do
        mock_user_sign_in
        get 'edit', id: 1
      end
      include_examples 'redirected request'
    end

    context 'when accessed by checkout person disallowed by settings' do
      before(:each) do
        mock_app_config(AC_DEFAULTS.merge(checkout_persons_can_edit: false))
        mock_user_sign_in(UserMock.new(:checkout_person))
        get 'edit', id: 1
      end
      include_examples 'redirected request'
    end

    shared_examples 'can access edit page' do
      let!(:item) { EquipmentItemMock.new(id: 1, name: 'Name') }
      before do
        model = EquipmentModelMock.new(traits: [[:with_item, item: item]])
        res = ReservationMock.new(equipment_model: model, id: 1,
                                  class: Reservation)
        allow(Reservation).to receive(:find).with(res.id.to_s)
          .and_return(res)
        get :edit, id: res.id
      end
      it 'assigns @option_array as Array' do
        expect(assigns(:option_array)).to be_an Array
      end
      it 'assigns @option_array with the correct contents' do
        expect(assigns(:option_array)).to eq([[item.name, item.id]])
      end
      it { is_expected.to render_template(:edit) }
    end

    context 'when accessed by checkout person allowed by settings' do
      before(:each) do
        mock_app_config(AC_DEFAULTS.merge(checkout_persons_can_edit: true))
        mock_user_sign_in(UserMock.new(:checkout_person))
      end
      it_behaves_like 'can access edit page'
    end

    context 'when accessed by admin' do
      before(:each) do
        mock_user_sign_in(UserMock.new(:admin))
      end
      include_examples 'can access edit page'
    end
  end

  describe '#update (PUT /reservations/:id)' do
    # Access: everyone who can access GET edit
    # Functionality:
    # - assign @reservation
    # - check due_date > start_date from params; if not, flash error and
    #     redirect back
    # - if params[:equipment_item] is defined, swap the item from the
    #     current reservation
    # - affect the current reservation (@reservation)
    # - set flash notice
    # - redirect to @reservation
    # Expects in params:
    # - params[:equipment_item] = id of equipment item or nil
    # - params[:reservation] with :start_date, :due_date, :reserver_id, :notes

    before(:all) do
      @user = FactoryGirl.create(:user)
      @checkout_person = FactoryGirl.create(:checkout_person)
      @admin = FactoryGirl.create(:admin)
    end
    after(:all) { User.destroy_all }
    before(:each) do
      @reservation = FactoryGirl.create(:valid_reservation, reserver: @user)
    end

    it_behaves_like 'inaccessible by banned user' do
      before { put :update }
    end

    context 'when accessed by patron' do
      before(:each) do
        sign_in @user
        put 'update', id: @reservation.id
      end
      include_examples 'redirected request'
    end

    context 'when accessed by checkout person disallowed by settings' do
      before(:each) do
        sign_in @checkout_person
        mock_app_config(AC_DEFAULTS.merge(checkout_persons_can_edit: false))
        put 'update',
            id: @reservation.id,
            reservation: FactoryGirl.attributes_for(:reservation)
      end
      include_examples 'redirected request'
    end

    ## Happy paths due to authorization
    shared_examples 'can access update page' do
      # Happy paths
      describe 'and provides valid params[:reservation]' do
        before(:each) do
          put :update,
              id: @reservation.id,
              reservation:
                FactoryGirl.attributes_for(:reservation,
                                           start_date: Time.zone.today,
                                           due_date: Time.zone.today + 4.days),
              equipment_item: ''
        end
        it 'should update the reservation details' do
          @reservation.reload
          expect(@reservation.start_date).to eq(Time.zone.today)
          expect(@reservation.due_date).to eq(Time.zone.today + 4.days)
        end
        it 'updates the reservations notes' do
          expect { @reservation.reload }.to change(@reservation, :notes)
        end
        it { is_expected.to redirect_to(@reservation) }
      end

      describe 'and provides valid params[:equipment_item]' do
        before(:each) do
          @new_equipment_item =
            FactoryGirl.create(:equipment_item,
                               equipment_model: @reservation.equipment_model)
          put :update,
              id: @reservation.id,
              reservation:
                FactoryGirl.attributes_for(:reservation,
                                           start_date: Time.zone.today,
                                           due_date: (Time.zone.today + 1.day)),
              equipment_item: @new_equipment_item.id
        end
        it 'should update the item on current reservation' do
          expect { @reservation.reload }.to\
            change { @reservation.equipment_item }
        end

        it 'should update the item notes' do
          expect { @new_equipment_item.reload }.to\
            change(@new_equipment_item, :notes)
        end

        it 'updates the reservations notes' do
          expect { @reservation.reload }.to change(@reservation, :notes)
        end

        it { is_expected.to redirect_to(@reservation) }

        context 'with existing equipment item' do
          before(:each) do
            @old_item =
              FactoryGirl.create(:equipment_item,
                                 equipment_model: @reservation.equipment_model)
            @new_item =
              FactoryGirl.create(:equipment_item,
                                 equipment_model: @reservation.equipment_model)
            put :update,
                id: @reservation.id,
                reservation: FactoryGirl
                  .attributes_for(:reservation,
                                  start_date: Time.zone.today,
                                  due_date: (Time.zone.today + 1.day)),
                equipment_item: @old_item.id
            @old_item.reload
            @new_item.reload
            put :update,
                id: @reservation.id,
                reservation: FactoryGirl
                  .attributes_for(:reservation,
                                  start_date: Time.zone.today,
                                  due_date: (Time.zone.today + 1.day)),
                equipment_item: @new_item.id
          end

          it 'should update both histories' do
            expect { @old_item.reload }.to change(@old_item, :notes)
            expect { @new_item.reload }.to change(@new_item, :notes)
          end

          it 'should make the other item available' do
            @old_item.reload
            expect(@old_item.status).to eq('available')
          end
        end

        context 'with checked out equipment item' do
          before(:each) do
            @old_item =
              FactoryGirl.create(:equipment_item,
                                 equipment_model: @reservation.equipment_model)
            @new_item =
              FactoryGirl.create(:equipment_item,
                                 equipment_model: @reservation.equipment_model)
            @other_res =
              FactoryGirl.create(:reservation,
                                 reserver: @user,
                                 equipment_model: @reservation.equipment_model)
            put :update,
                id: @reservation.id,
                reservation:
                  FactoryGirl.attributes_for(:reservation,
                                             start_date: Time.zone.today,
                                             due_date: Time.zone.today + 1.day),
                equipment_item: @old_item.id
            put :update,
                id: @other_res.id,
                reservation:
                  FactoryGirl.attributes_for(:reservation,
                                             start_date: Time.zone.today,
                                             due_date: Time.zone.today + 1.day),
                equipment_item: @new_item.id
            @old_item.reload
            @new_item.reload
            put :update,
                id: @reservation.id,
                reservation:
                  FactoryGirl.attributes_for(:reservation,
                                             start_date: Time.zone.today,
                                             due_date: Time.zone.today + 1.day),
                equipment_item: @new_item.id
          end

          it 'should update both histories' do
            expect { @old_item.reload }.to change(@old_item, :notes)
            expect { @new_item.reload }.to change(@new_item, :notes)
          end

          it 'should be noted in the other reservation' do
            expect { @other_res.reload }.to change(@other_res, :notes)
          end
        end
      end

      # Unhappy path
      describe 'and provides invalid params[:reservation]' do
        before(:each) do
          request.env['HTTP_REFERER'] = reservation_path(@reservation)
          put :update,
              id: @reservation.id,
              reservation:
                FactoryGirl.attributes_for(:reservation,
                                           start_date: Time.zone.today,
                                           due_date: Time.zone.today - 1.day),
              equipment_item: ''
        end
        include_examples 'redirected request'

        it 'does not update the reservations notes' do
          expect { @reservation.reload }.not_to change(@reservation, :notes)
        end
      end
    end

    context 'when accessed by checkout person allowed by settings' do
      before(:each) do
        mock_app_config(AC_DEFAULTS.merge(checkout_persons_can_edit: true))
        sign_in @checkout_person
      end
      include_examples 'can access update page'
    end

    context 'when accessed by admin' do
      before(:each) { sign_in @admin }
      include_examples 'can access update page'
    end
  end

  describe '#destroy (DELETE /reservations/:id)' do
    # SMELL: this mostly tests permissions
    # Special access:
    # - checkout persons, if checked_out is nil
    # - users, if checked_out is nil and it's their reservation
    # Functionality:
    # - destroy reservation, set flash[:notice], redirect to reservations_url

    ADMIN_ROLES = [:admin, :checkout_person].freeze

    shared_examples 'can destroy reservation' do
      before { delete :destroy, id: res.id }
      it { is_expected.to redirect_to(reservations_url) }
      it { is_expected.to set_flash[:notice] }
      it 'deletes the reservation' do
        expect(res).to have_received(:destroy)
      end
    end

    shared_examples 'cannot destroy reservation' do
      before { delete :destroy, id: res.id }
      include_examples 'redirected request'
    end

    ADMIN_ROLES.each do |role|
      before { mock_user_sign_in(UserMock.new(role)) }
      let!(:res) { ReservationMock.new(traits: [:findable]) }
      it_behaves_like 'can destroy reservation'
    end

    context 'when accessed by patron' do
      let!(:user) { UserMock.new }
      before { mock_user_sign_in(user) }

      context 'and the reservation is their own' do
        context 'and it is checked out' do
          let!(:res) do
            ReservationMock.new(traits: [:findable], reserver: user,
                                status: 'checked_out')
          end
          it_behaves_like 'cannot destroy reservation'
        end
        context 'and it is not checked out' do
          let!(:res) do
            ReservationMock.new(traits: [:findable], reserver: user)
          end
          it_behaves_like 'can destroy reservation'
        end
      end
      context 'and the reservation is not their own' do
        let!(:res) { ReservationMock.new(traits: [:findable]) }
        it_behaves_like 'cannot destroy reservation'
      end
    end

    it_behaves_like 'inaccessible by banned user' do
      let!(:res) { ReservationMock.new(traits: [:findable]) }
      before do
        allow(User).to receive(:find_by_id)
        delete :destroy, id: res.id
      end
    end
  end

  describe '#current (GET /reservations/current/:user_id)' do
    # not particularily messy but the method is written in a way that
    # makes mocking + stubbing difficult
    # SMELL: feature envy: everything depends on @user

    before(:all) do
      @user = FactoryGirl.create(:user)
      @checkout_person = FactoryGirl.create(:checkout_person)
      @admin = FactoryGirl.create(:admin)
      @banned = FactoryGirl.create(:banned)
    end
    after(:all) do
      User.destroy_all
    end

    shared_examples 'can access #current' do
      before { get :current, user_id: @user.id }
      it { expect(response).to be_success }
      it { is_expected.to render_template(:current_reservations) }

      it 'assigns @user correctly' do
        expect(assigns(:user)).to eq(@user)
      end

      it 'assigns @user_overdue_reservations_set correctly' do
        expect(assigns(:user_overdue_reservations_set)).to\
          eq [Reservation.overdue.for_reserver(@user)].delete_if(&:empty?)
      end

      it 'assigns @user_checked_out_today_reservations_set correctly' do
        expect(assigns(:user_checked_out_today_reservations_set)).to\
          eq [Reservation.checked_out_today.for_reserver(@user)]
          .delete_if(&:empty?)
      end

      it 'assigns @user_checked_out_previous_reservations_set correctly' do
        expect(assigns(:user_checked_out_previous_reservations_set)).to\
          eq [Reservation.checked_out_previous.for_reserver(@user)]
          .delete_if(&:empty?)
      end

      it 'assigns @user_reserved_reservations_set correctly' do
        expect(assigns(:user_reserved_reservations_set)).to\
          eq [Reservation.reserved.for_reserver(@user)].delete_if(&:empty?)
      end
    end

    context 'when accessed by admin' do
      before(:each) do
        sign_in @admin
      end

      include_examples 'can access #current'
    end

    context 'when accessed by checkout person' do
      before(:each) do
        sign_in @checkout_person
      end

      include_examples 'can access #current'
    end

    context 'when accessed by patron' do
      before(:each) do
        sign_in @user
        get :current, user_id: @user.id
      end

      include_examples 'redirected request'
    end

    it_behaves_like 'inaccessible by banned user' do
      before { get :current, user_id: @banned.id }
    end

    context 'with banned reserver' do
      before(:each) do
        sign_in @admin
        get :current, user_id: @banned.id
      end

      it 'is a redirect' do
        expect(response).to be_redirect
      end

      it 'sets the flash' do
        expect(flash[:error]).not_to be_nil
      end
    end
  end

  describe '#renew (PUT /reservations/:id/renew)' do
    # SMELL: this mostly tests permissions
    shared_examples 'can renew reservation' do
      before(:each) do
        allow(Reservation).to receive(:find).with(res.id.to_s).and_return(res)
        allow(res).to receive(:renew).and_return(nil)
        put :renew, id: res.id
      end
      it { is_expected.to redirect_to(reservation_path(res)) }
      it { is_expected.to set_flash[:notice] }
    end

    context 'when accessed by admin' do
      let!(:res) { FactoryGirl.build_stubbed(:valid_reservation) }
      before { mock_user_sign_in(UserMock.new(:admin)) }
      include_examples 'can renew reservation'
      context 'cannot renew' do
        before do
          allow(Reservation).to receive(:find).with(res.id.to_s).and_return(res)
          allow(res).to receive(:renew).and_return('error')
          put :renew, id: res.id
        end
        it { is_expected.to redirect_to(reservation_path(res)) }
        it { is_expected.to set_flash[:error] }
      end
    end

    context 'when accessed by checkout person' do
      let!(:res) { FactoryGirl.build_stubbed(:valid_reservation) }
      before { mock_user_sign_in(UserMock.new(:checkout_person)) }
      include_examples 'can renew reservation'
    end

    context 'when accessed by patron' do
      let!(:user) { FactoryGirl.build_stubbed(:user) }
      before { mock_user_sign_in user }
      context 'own reservation' do
        let!(:res) do
          FactoryGirl.build_stubbed(:valid_reservation, reserver: user)
        end
        include_examples 'can renew reservation'
      end
      context 'trying to renew someone elses reservation' do
        let!(:res) { FactoryGirl.build_stubbed(:valid_reservation) }
        before { put :renew, id: res.id }
        it { expect(response).to be_redirect }
      end
    end

    # FIXME: fails
    it_behaves_like 'inaccessible by banned user' do
      let!(:res) { FactoryGirl.build_stubbed(:valid_reservation) }
      before do
        allow(Reservation).to receive(:find).with(res.id.to_s).and_return(res)
        put :renew, id: res.id
      end
    end
  end

  describe '#archive (PUT /reservations/:id/archive)' do
    # Access: Admins
    # Functionality:
    # - requests note from admin
    # - sets @reservation
    # - sets @reservation.checked_in to today
    # - adds archival comment to note
    # - redirects to @reservation

    before(:all) do
      @user = FactoryGirl.create(:user)
      @checkout_person = FactoryGirl.create(:checkout_person)
      @admin = FactoryGirl.create(:admin)
      @banned = FactoryGirl.create(:banned)
    end

    after(:all) { User.destroy_all }

    before(:each) do
      sign_in @user
      @reservation = FactoryGirl.create(:valid_reservation, reserver: @user)
    end

    shared_examples 'cannot archive reservation' do
      before do
        request.env['HTTP_REFERER'] = reservation_path(@reservation)
        put :archive, id: @reservation.id, archive_note: "I can't!"
      end

      it { expect(response).to redirect_to(root_path) }
      it 'should not be checked in' do
        expect { @reservation.reload }.not_to change { @reservation.checked_in }
      end
      it 'should not have new notes' do
        expect { @reservation.reload }.not_to change { @reservation.notes }
      end
    end

    context 'for checked-out reservation' do
      before(:each) do
        @reservation =
          FactoryGirl.create(:checked_out_reservation, reserver: @user)
        request.env['HTTP_REFERER'] = reservation_path(@reservation)
      end

      context 'when accessed by admin' do
        before(:each) do
          allow(@controller).to receive(:current_user).and_return(@admin)
        end

        context 'with archive note' do
          before(:each) do
            put :archive, id: @reservation.id, archive_note: 'Because I can'
          end

          it 'redirects to reservation show view' do
            expect(response).to redirect_to(reservation_path(@reservation))
          end
          it 'should be checked in' do
            expect { @reservation.reload }.to change { @reservation.checked_in }
          end
          it 'should have new notes' do
            expect { @reservation.reload }.to change { @reservation.notes }
          end
        end

        context 'without archive note' do
          before(:each) do
            put :archive, id: @reservation.id
          end

          it 'redirects to reservation show view' do
            expect(response).to redirect_to(reservation_path(@reservation))
          end
          it 'should not be checked in' do
            expect(@reservation.checked_in).to be_nil
          end
          it 'should not have new notes' do
            expect { @reservation.reload }.not_to change { @reservation.notes }
          end
        end

        context 'when auto-deactivate is enabled' do
          before(:each) do
            mock_app_config(AC_DEFAULTS.merge(autodeactivate_on_archive: true))
            put :archive, id: @reservation.id, archive_note: 'Because I can'
          end

          it 'should deactivate the equipment item' do
            ei = @reservation.equipment_item.reload
            expect(ei.deleted_at).not_to be_nil
            expect(ei.deactivation_reason).to \
              include('Because I can')
          end
        end
      end

      context 'when accessed by checkout person' do
        before(:each) do
          allow(@controller).to\
            receive(:current_user).and_return(@checkout_person)
        end

        include_examples 'cannot archive reservation'
      end

      context 'when accessed by patron' do
        before(:each) do
          allow(@controller).to receive(:current_user).and_return(@user)
        end

        include_examples 'cannot archive reservation'
      end
    end

    context 'for checked-in reservations' do
      before(:each) do
        allow(@controller).to receive(:current_user).and_return(@admin)
        @reservation =
          FactoryGirl.build(:checked_in_reservation, reserver: @user)
        @reservation.save(validate: false)
        request.env['HTTP_REFERER'] = reservation_path(@reservation)
        put :archive, id: @reservation.id, archive_note: 'Because I can'
      end

      it 'redirects to reservation show view' do
        expect(response).to redirect_to(reservation_path(@reservation))
      end
      it 'should not change reservation' do
        expect { @reservation.reload }.not_to change { @reservation.checked_in }
        expect { @reservation.reload }.not_to change { @reservation.notes }
      end
    end

    it_behaves_like 'inaccessible by banned user' do
      before do
        allow(User).to receive(:find).with(@user.id).and_return(@user)
        @reservation =
          FactoryGirl.create(:checked_out_reservation, reserver: @user)
        put :archive, id: @reservation.id
      end
    end
  end

  describe '#review GET' do
    let!(:res) { ReservationMock.new(traits: [:findable]) }
    context 'as admin' do
      before do
        mock_user_sign_in(UserMock.new(:admin))
      end
      it 'should assign all current requests except itself' do
        other = ReservationMock.new(traits: [:findable])
        full = [res, other]
        expect(res).to \
          receive_message_chain(:reserver, :reservations, :requested)
          .and_return(full)
        get :review, id: res.id
        expect(assigns(:all_current_requests_by_user)).to eq([other])
      end
      it 'should assign errors' do
        allow(res).to \
          receive_message_chain(:reserver, :reservations, :requested)
          .and_return([])
        allow(res).to receive(:validate).and_return('errors')
        get :review, id: res.id
        expect(assigns(:errors)).to eq('errors')
      end
    end
  end

  describe '#approve_request PUT' do
    # SMELL: this doesn't belong in the controller
    before(:all) { @admin = FactoryGirl.create(:admin) }
    after(:all) { User.destroy_all }

    before do
      sign_in @admin
      @requested = FactoryGirl.create(:request)
      put :approve_request, id: @requested.id
    end
    it 'should set the reservation status' do
      expect(assigns(:reservation).status).to eq('reserved')
    end
    it 'should save the reservation' do
      expect(@requested.reload.status).to eq('reserved')
    end
    it 'should send an email' do
      expect_email(UserMailer.reservation_status_update(@requested))
    end
    it 'should redirect to reservations path' do
      expect(response).to redirect_to(reservations_path(requested: true))
    end
  end

  describe '#deny_request PUT' do
    # SMELL: this doesn't belong in the controller
    before(:all) { @admin = FactoryGirl.create(:admin) }
    after(:all) { User.destroy_all }

    before do
      sign_in @admin
      @requested = FactoryGirl.create(:request)
      put :deny_request, id: @requested.id
    end
    it 'should set the reservation status to denied' do
      expect(assigns(:reservation).status).to eq('denied')
    end
    it 'should save the reservation' do
      expect(@requested.reload.status).to eq('denied')
    end
    it 'should send an email' do
      expect_email(UserMailer.reservation_status_update(@requested))
    end
    it 'should redurect to reservations path' do
      expect(response).to redirect_to(reservations_path(requested: true))
    end
  end
end
