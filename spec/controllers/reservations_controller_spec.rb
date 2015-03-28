require 'spec_helper'
require 'helpers/email_helper_spec'

describe ReservationsController, type: :controller do
  ## Common setup
  render_views

  before(:all) do
    @app_config = FactoryGirl.create(:app_config)

    @user = FactoryGirl.create(:user)
    @banned = FactoryGirl.create(:banned)
    @checkout_person = FactoryGirl.create(:checkout_person)
    @admin = FactoryGirl.create(:admin)
  end

  after(:all) do
    User.delete_all
    AppConfig.delete_all
    Reservation.delete_all
    Category.delete_all
    EquipmentModel.delete_all
    EquipmentItem.delete_all
  end

  before(:each) do
    @cart = FactoryGirl.build(:cart, reserver_id: @user.id)

    sign_in @user

    @reservation = FactoryGirl.create(:valid_reservation, reserver: @user)
  end

  ## Shared examples
  shared_examples 'cannot access page' do
    it { expect(response).to be_redirect }
    it { is_expected.to set_flash }
  end

  shared_examples 'inaccessible by banned user' do
    before(:each) do
      sign_in @banned
      allow(Reservation).to receive(:find)
        .and_return(FactoryGirl.build_stubbed(:reservation, reserver: @banned))
    end
    include_examples 'cannot access page'
    it { is_expected.to redirect_to(root_path) }
  end

  describe '#update_index_dates (PUT)' do
    subject do
      put :update_index_dates, list: { start_date: Time.zone.today.to_s,
                                       end_date: (Time.zone.today + 1.day).to_s,
                                       filter: :reserved.to_s }
    end
    it { is_expected.to be_redirect }
    before(:each) do
      @start = Time.zone.today
      @end = (Time.zone.today + 1.day)
      @filter = :reserved
      put :update_index_dates, list: { start_date: @start.to_s,
                                       end_date: @end.to_s,
                                       filter: @filter.to_s }
    end
    it 'disables all_date viewing' do
      expect(session[:all_dates]).to be_falsey
    end
    it 'sets the session dates' do
      expect(session[:index_start_date]).to eq(@start)
      expect(session[:index_end_date]).to eq(@end)
    end
    it 'sets the session filter' do
      expect(session[:filter]).to eq(@filter)
    end
  end

  describe '#view_all_dates (PUT)' do
    subject { put :view_all_dates }
    it { is_expected.to be_redirect }
    before(:each) do
      put :view_all_dates
    end
    it 'enables all_date viewing' do
      expect(session[:all_dates]).to be_truthy
    end
  end

  ## Controller method tests
  describe '#index (GET /reservations/)' do
    # check params[:filter]
    # depending on admin status, default_filter changes
    # depending on admin status, source of reservations (all v. own) changes

    before(:all) do
      @filters = [:reserved, :checked_out, :overdue, :missed,
                  :returned, :upcoming]
    end

    context 'when accessed by non-banned user' do
      subject { get :index }
      it { is_expected.to be_success }
      it { is_expected.to render_template(:index) }

      it 'populates @reservations_set with respect to params[filter]' do
        # Setup
        @filters.each do |trait|
          res = FactoryGirl.build(:valid_reservation, trait, reserver: @user)
          res.save(validate: false)
        end

        # Assertion and expectation
        @filters.each do |f|
          get :index, f => true
          expect(assigns(:reservations_set).uniq.sort).to eq(Reservation.send(f)
               .starts_on_days(assigns(:start_date), assigns(:end_date))
               .uniq.sort)
        end
      end
      it 'populates with respect to session[:filter] first' do
        @filters.each do |trait|
          res = FactoryGirl.build(:valid_reservation, trait, reserver: @user)
          res.save(validate: false)
        end

        # Assertion and expectation
        @filters.each do |f|
          session[:filter] = f.to_s
          get :index, @filters.sample => true
          expect(assigns(:reservations_set).uniq.sort).to eq(Reservation.send(f)
               .starts_on_days(assigns(:start_date), assigns(:end_date))
               .uniq.sort)
        end
      end

      context 'who is an admin' do
        before(:each) do
          sign_in @admin
          @filters.each do |trait|
            res = FactoryGirl.build(:valid_reservation, trait,
                                    reserver: [@user, @admin].sample)
            res.save(validate: false)
          end
        end
        it 'uses :upcoming as default filter' do
          get :index
          expect(assigns(:reservations_set) - Reservation.upcoming.all)
            .to be_empty
        end
      end

      context 'who is not an admin' do
        before(:each) do
          sign_in @user
          @filters.each do |trait|
            res = FactoryGirl.build(:valid_reservation, trait,
                                    reserver: [@user, @admin].sample)
            res.save(validate: false)
          end
        end

        it 'uses :reserved as the default filter' do
          get :index
          expect(assigns(:reservations_set) - @user.reservations.reserved)
            .to be_empty
        end
      end
    end

    it_behaves_like 'inaccessible by banned user' do
      before { get :index }
    end
  end

  describe '#show (GET /reservations/:id)' do
    before(:each) do
      @admin_res = FactoryGirl.create(:valid_reservation, reserver: @admin)
    end

    shared_examples 'can view reservation by patron' do
      before(:each) { get :show, id: @reservation.id }
      it { is_expected.to render_template(:show) }
      it { expect(response).to be_success }
      it { expect(assigns(:reservation)).to eq @reservation }
    end

    shared_examples 'can view reservation by admin' do
      before(:each) { get :show, id: @admin_res.id }
      it { is_expected.to render_template(:show) }
      it { expect(response).to be_success }
      it { expect(assigns(:reservation)).to eq @admin_res }
    end

    shared_examples 'cannot view reservation by admin' do
      before(:each) { get :show, id: @admin_res.id }
      include_examples 'cannot access page'
    end

    context 'when accessed by admin' do
      before(:each) do
        sign_in @admin
      end

      it_behaves_like 'can view reservation by patron'
      it_behaves_like 'can view reservation by admin'
    end

    context 'when accessed by checkout person' do
      before(:each) do
        sign_in @checkout_person
      end

      it_behaves_like 'can view reservation by patron'
      it_behaves_like 'can view reservation by admin'
    end

    context 'when accessed by patron' do
      before(:each) do
        sign_in @user
      end

      it_behaves_like 'can view reservation by patron'
      it_behaves_like 'cannot view reservation by admin'
    end

    it_behaves_like 'inaccessible by banned user' do
      before { get :show, id: @reservation.id }
    end
  end

  describe '#new (GET /reservations/new)' do
    # unhappy paths: banned user, there is no reservation in the cart
    it_behaves_like 'inaccessible by banned user' do
      before { get :new }
    end

    context 'when accessed by a non-banned user' do
      before(:each) { sign_in @user }

      context 'with an empty cart' do
        before(:each) do
          get :new
        end
        it { expect(response).to be_redirect }
        it { is_expected.to set_flash }
      end

      context 'with a non-empty cart' do
        before(:each) do
          @cart = FactoryGirl.build(:cart_with_items, reserver_id: @user.id)
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
            AppConfig.first.update_attributes(override_on_create: true)
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
            AppConfig.first.update_attributes(override_on_create: false)
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
    ## Unhappy paths
    it_behaves_like 'inaccessible by banned user' do
      before { get 'edit', id: @reservation.id }
    end

    context 'when accessed by patron' do
      before(:each) do
        sign_in @user
        get 'edit', id: @reservation.id
      end
      include_examples 'cannot access page'
    end

    context 'when accessed by checkout person disallowed by settings' do
      before(:each) do
        sign_in @checkout_person
        AppConfig.first.update_attributes(checkout_persons_can_edit: false)
        get 'edit', id: @reservation.id
      end
      include_examples 'cannot access page'
    end

    ## Happy paths
    shared_examples 'can access edit page' do
      it 'assigns @reservation' do
        expect(assigns(:reservation)).to eq(@reservation)
      end
      it 'assigns @option_array as Array' do
        expect(assigns(:option_array)).to be_an Array
      end
      it 'assigns @option_array with the correct contents' do
        expect(assigns(:option_array)).to\
          eq @reservation.equipment_model.equipment_items
            .collect { |e| [e.name, e.id] }
      end
      it { is_expected.to render_template(:edit) }
    end

    context 'when accessed by checkout person allowed by settings' do
      before(:each) do
        sign_in @checkout_person
        AppConfig.first.update_attributes(checkout_persons_can_edit: true)
        get :edit, id: @reservation.id
      end
      include_examples 'can access edit page'
    end

    context 'when accessed by admin' do
      before(:each) do
        sign_in @admin
        AppConfig.first.update_attributes(checkout_persons_can_edit: false)
        get :edit, id: @reservation.id
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

    ## Unhappy paths due to authorization
    it_behaves_like 'inaccessible by banned user' do
      before { put :update }
    end

    context 'when accessed by patron' do
      before(:each) do
        sign_in @user
        put 'update', id: @reservation.id
      end
      include_examples 'cannot access page'
    end

    context 'when accessed by checkout person disallowed by settings' do
      before(:each) do
        sign_in @checkout_person
        AppConfig.first.update_attributes(checkout_persons_can_edit: false)
        put 'update',
            id: @reservation.id,
            reservation: FactoryGirl.attributes_for(:reservation)
      end
      include_examples 'cannot access page'
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
        include_examples 'cannot access page'

        it 'does not update the reservations notes' do
          expect { @reservation.reload }.not_to change(@reservation, :notes)
        end
      end
    end

    context 'when accessed by checkout person allowed by settings' do
      before(:each) do
        sign_in @checkout_person
        AppConfig.first.update_attributes(checkout_persons_can_edit: true)
      end
      include_examples 'can access update page'
    end

    context 'when accessed by admin' do
      before(:each) do
        sign_in @admin
        AppConfig.first.update_attributes(checkout_persons_can_edit: false)
      end
      include_examples 'can access update page'
    end
  end

  describe '#destroy (DELETE /reservations/:id)' do
    # Special access:
    # - checkout persons, if checked_out is nil
    # - users, if checked_out is nil and it's their reservation
    # Functionality:
    # - destroy reservation, set flash[:notice], redirect to reservations_url

    # Requires a block to be passed which defines let!(:reservation)
    shared_examples 'can destroy reservation' do
      it 'deletes the reservation' do
        expect { delete :destroy, id: reservation.id }.to\
          change { Reservation.count }
      end

      it 'redirects to reservations_url' do
        delete :destroy, id: reservation.id
        expect(response).to redirect_to(reservations_url)
      end

      it 'sets the flash' do
        delete :destroy, id: reservation.id
        expect(flash[:notice]).not_to be_nil
      end
    end

    # Requires a block to be passed which defines let(:reservation)
    shared_examples 'cannot destroy reservation' do
      before(:each) { delete :destroy, id: reservation.id }
      include_examples 'cannot access page'
    end

    context 'when accessed by admin' do
      before(:each) do
        sign_in @admin
      end

      include_examples 'can destroy reservation' do
        let!(:reservation) do
          FactoryGirl.create(:valid_reservation, reserver: @user)
        end
      end
    end

    context 'when accessed by checkout person' do
      before(:each) do
        sign_in @checkout_person
      end

      context 'and the reservation is checked out' do
        include_examples 'cannot destroy reservation' do
          let(:reservation) do
            FactoryGirl.create(:checked_out_reservation, reserver: @user)
          end
        end
      end

      context 'and the reservation is not checked out' do
        include_examples 'can destroy reservation' do
          let!(:reservation) do
            FactoryGirl.create(:valid_reservation, reserver: @user)
          end
        end
      end
    end

    context 'when accessed by patron' do
      before(:each) do
        sign_in @user
      end

      context 'and the reservation is their own' do
        context 'and it is checked out' do
          include_examples 'cannot destroy reservation' do
            let(:reservation) do
              FactoryGirl.create(:checked_out_reservation, reserver: @user)
            end
          end
        end

        context 'and it is not checked out' do
          include_examples 'can destroy reservation' do
            let!(:reservation) do
              FactoryGirl.create(:valid_reservation, reserver: @user)
            end
          end
        end
      end

      context 'and the reservation is not their own' do
        include_examples 'cannot destroy reservation' do
          let(:reservation) do
            FactoryGirl.create(:valid_reservation, reserver: @checkout_person)
          end
        end
      end
    end

    it_behaves_like 'inaccessible by banned user' do
      before { delete :destroy, id: @reservation.id }
    end
  end

  describe '#manage (GET /reservations/manage/:user_id)' do
    # Access: admins and checkout persons
    # Functionality:
    # - assigns @user, @check_out_set and @check_in_set
    # - renders :manage

    shared_examples 'can access #manage' do
      before(:each) { get :manage, user_id: @user.id }
      it { expect(response).to be_success }
      it { is_expected.to render_template(:manage) }

      it 'assigns @user correctly' do
        expect(assigns(:user)).to eq(@user)
      end

      it 'assigns @check_out_set correctly' do
        expect(assigns(:check_out_set)).to eq(@user.due_for_checkout)
      end

      it 'assigns @check_in_set correctly' do
        expect(assigns(:check_in_set)).to eq(@user.due_for_checkin)
      end
    end

    context 'when accessed by admin' do
      before(:each) do
        sign_in @admin
      end

      include_examples 'can access #manage'
    end

    context 'when accessed by checkout person' do
      before(:each) do
        sign_in @checkout_person
      end

      include_examples 'can access #manage'
    end

    context 'when accessed by patron' do
      before(:each) do
        sign_in @user
        get :manage, user_id: @user.id
      end

      include_examples 'cannot access page'
    end

    it_behaves_like 'inaccessible by banned user' do
      before { get :manage, user_id: @banned.id }
    end

    context 'with banned reserver' do
      before(:each) do
        sign_in @admin
        get :manage, user_id: @banned.id
      end

      it 'is a redirect' do
        expect(response).to be_redirect
      end

      it 'sets the flash' do
        expect(flash[:error]).not_to be_nil
      end
    end
  end

  describe '#current (GET /reservations/current/:user_id)' do
    # Access: admins and checkout persons
    # Functionality:
    # - assigns @user, @user_overdue_reservations_set,
    #    @user_checked_out_today_reservations_set,
    #    @user_checked_out_previous_reservations_set,
    #    @user_reserved_reservations_set
    # - renders :current_reservations

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

      include_examples 'cannot access page'
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

  describe '#checkout (PUT /reservations/checkout/:user_id)' do
    # Access: Admins, checkout persons.
    # Functionality: very complicated (almost 100 lines)
    # - pass TOS (if not, redirect)
    # - params[:reservations] contains hash of
    #    {reservation_id => {equipment_item_id: int, notes: str,
    #      checkout_precedures: {checkout_procedure_id => int}}}
    # - stops checkout if user has overdue reservations
    # - stops checkout if no reservations are selected
    # - overrides errors if you can and if there are some, otherwise
    #     redirects away
    # - also prevents checkout if reserver is banned

    # Effects if successful:
    # - sets empty @check_in_set, populates @check_out_set with the
    #     reservations
    # - processes all reservations in params[:reservations] -- adds
    #     checkout_handler, checked_out (time), equipment_item; updates
    #     notes
    # - renders :receipt template

    # Note: Many of these can be cross-applied to #checkin as well

    shared_examples 'has successful checkout' do
      before(:each) do
        @item =
          FactoryGirl.create(:equipment_item,
                             equipment_model: @reservation.equipment_model)
        reservations_params =
          { @reservation.id.to_s => { notes: '',
                                      equipment_item_id: @item.id } }
        put :checkout, user_id: @user.id, reservations: reservations_params
      end

      it { expect(response).to be_success }
      it { is_expected.to render_template(:receipt) }

      it 'assigns empty @check_in_set' do
        expect(assigns(:check_in_set)).to be_empty
      end

      it 'populates @check_out_set' do
        expect(assigns(:check_out_set)).to eq [@reservation]
      end

      it 'updates the reservation' do
        expect(@reservation.checkout_handler).to be_nil
        expect(@reservation.checked_out).to be_nil
        expect(@reservation.equipment_item).to be_nil
        @reservation.reload
        expect(@reservation.checkout_handler).to be_a(User)
        expect(@reservation.checked_out).to_not be_nil
        expect(@reservation.equipment_item).to eq @item
      end

      it 'updates the equipment item history' do
        expect { @item.reload }.to change(@item, :notes)
      end

      it 'updates the reservation notes' do
        expect { @reservation.reload }.to change(@reservation, :notes)
      end
    end

    context 'when accessed by admin' do
      before(:each) do
        sign_in @admin
      end

      include_examples 'has successful checkout'
    end

    context 'when accessed by checkout person' do
      before(:each) do
        sign_in @checkout_person
      end

      include_examples 'has successful checkout'
    end

    context 'when accessed by patron' do
      before(:each) do
        sign_in @user
        put :checkout, user_id: @user.id
      end

      include_examples 'cannot access page'
    end

    it_behaves_like 'inaccessible by banned user' do
      before { put :checkout, user_id: @banned.id }
    end

    context 'when tos returns false' do
      before do
        request.env['HTTP_REFERER'] = 'where_i_came_from'
        sign_in @admin
        allow(@controller).to receive(:check_tos).and_return(false)
        put :checkout, user_id: @user.id, reservations: {}
      end
      it { expect(response).to redirect_to 'where_i_came_from' }
    end

    context 'when not all procedures are filled out' do
      before do
        sign_in @admin
        @item =
          FactoryGirl.create(:equipment_item,
                             equipment_model: @reservation.equipment_model)
        @procedure =
          FactoryGirl.create(:checkout_procedure,
                             equipment_model: @reservation.equipment_model)
        reservations_params =
          { @reservation.id.to_s => { notes: '',
                                      equipment_item_id: @item.id,
                                      checkout_procedures: {} } }
        put :checkout, user_id: @user.id, reservations: reservations_params
      end

      it { expect(response).to be_success }

      it { is_expected.to render_template(:receipt) }

      it 'assigns empty @check_in_set' do
        expect(assigns(:check_in_set)).to be_empty
      end

      it 'populates @check_out_set' do
        expect(assigns(:check_out_set)).to eq [@reservation]
      end

      it 'updates the reservation' do
        expect(@reservation.checkout_handler).to be_nil
        expect(@reservation.checked_out).to be_nil
        expect(@reservation.equipment_item).to be_nil
        @reservation.reload
        expect(@reservation.checkout_handler).to be_a(User)
        expect(@reservation.checked_out).to_not be_nil
        expect(@reservation.equipment_item).to eq @item
        expect(@reservation.notes).to include(@procedure.step)
      end
    end

    context 'no reservations selected' do
      before do
        reservations_params = {}
        request.env['HTTP_REFERER'] = 'where_i_came_from'
        sign_in @checkout_person
        put :checkout, user_id: @user.id, reservations: reservations_params
      end
      it { is_expected.to set_flash }
      it { expect(response).to redirect_to 'where_i_came_from' }
    end

    context 'reserver has overdue reservations' do
      context 'can override reservations?' do
        before do
          sign_in @admin
          @item =
            FactoryGirl.create(:equipment_item,
                               equipment_model: @reservation.equipment_model)
          reservations_params =
            { @reservation.id.to_s => { notes: '',
                                        equipment_item_id: @item.id } }
          overdue =
            FactoryGirl.build(:overdue_reservation, reserver_id: @user.id)
          overdue.save(validate: false)
          put :checkout, user_id: @user.id, reservations: reservations_params
        end
        it { expect(response).to be_success }
        it { is_expected.to render_template(:receipt) }
      end

      context 'cannot override' do
        before do
          request.env['HTTP_REFERER'] = 'where_i_came_from'
          sign_in @checkout_person
          @item =
            FactoryGirl.create(:equipment_item,
                               equipment_model: @reservation.equipment_model)
          reservations_params =
            { @reservation.id.to_s => { notes: '',
                                        equipment_item_id: @item.id } }
          overdue =
            FactoryGirl.build(:overdue_reservation, reserver_id: @user.id)
          overdue.save(validate: false)
          put :checkout, user_id: @user.id, reservations: reservations_params
        end
        it { is_expected.to set_flash }
        it { expect(response).to redirect_to 'where_i_came_from' }
      end
    end

    context 'with banned reserver' do
      before(:each) do
        @reservation.update_attribute(:reserver_id, @banned.id)
        request.env['HTTP_REFERER'] = 'where_i_came_from'
        sign_in @checkout_person
        @obj =
          FactoryGirl.create(:equipment_item,
                             equipment_model: @reservation.equipment_model)
        reservations_params =
          { @reservation.id.to_s => { notes: '',
                                      equipment_item_id: @obj.id } }
        put :checkout, user_id: @banned.id, reservations: reservations_params
      end

      it { is_expected.to set_flash }
      it { expect(response).to redirect_to root_path }
    end
  end

  describe '#checkin (PUT /reservations/check-in/:user_id)' do
    # Access: Admins, checkout persons.
    # Functionality: very complicated (almost 80 lines)
    # - params[:reservations] contains a hash of
    #    {reservation_id => {checkin?: int, notes: str,
    #      (nil?) checkin_procedures: {checkin_procedure_id => int}}}
    # - processes all reservations in params[:reservations] -- adds
    #     checkin_handler, checked_in (time); updates notes
    # - stops checkin if no reservations are selected
    # - overrides errors if you can and if there are some, otherwise
    #     redirects away
    # - renders :receipt template

    shared_examples 'has successful checkin' do
      before(:each) do
        @reservation =
          FactoryGirl.create(:checked_out_reservation, reserver: @user)
        @item = @reservation.equipment_item
        reservations_params =
          { @reservation.id.to_s => { notes: '', checkin?: '1' } }
        put :checkin, user_id: @user.id, reservations: reservations_params
      end

      it { expect(response).to be_success }
      it { is_expected.to render_template(:receipt) }

      it 'assigns empty @check_out_set' do
        expect(assigns(:check_out_set)).to be_empty
      end

      it 'populates @check_in_set' do
        expect(assigns(:check_in_set)).to eq [@reservation]
      end

      it 'updates the reservation' do
        expect(@reservation.checkin_handler).to be_nil
        expect(@reservation.checked_in).to be_nil
        @reservation.reload
        expect(@reservation.checkin_handler).to be_a(User)
        expect(@reservation.checked_in).to_not be_nil
      end

      it 'updates the equipment item history' do
        expect { @item.reload }.to change(@item, :notes)
      end

      it 'updates the reservation notes' do
        expect { @reservation.reload }.to change(@reservation, :notes)
      end
    end

    context 'when accessed by admin' do
      before(:each) do
        sign_in @admin
      end

      include_examples 'has successful checkin'
    end

    context 'when accessed by checkout person' do
      before(:each) do
        sign_in @checkout_person
      end

      include_examples 'has successful checkin'
    end

    context 'when accessed by patron' do
      before(:each) do
        sign_in @user
        put :checkin, user_id: @user.id
      end

      include_examples 'cannot access page'
    end

    it_behaves_like 'inaccessible by banned user' do
      before { put :checkin, user_id: @banned.id }
    end

    context 'items have already been checked in' do
      before do
        sign_in @admin
        request.env['HTTP_REFERER'] = 'where_i_came_from'
        @reservation =
          FactoryGirl.build(:checked_in_reservation, reserver: @user)
        @reservation.save(validate: false)
        reservations_params =
          { @reservation.id.to_s => { notes: '', checkin?: '1' } }
        put :checkin, user_id: @user.id, reservations: reservations_params
      end

      it { is_expected.to set_flash }
      it { expect(response).to redirect_to 'where_i_came_from' }
    end

    context 'no reservations to check in' do
      before do
        request.env['HTTP_REFERER'] = 'where_i_came_from'
        sign_in @admin
        put :checkin,  user_id: @user.id, reservations: {}
      end
      it { is_expected.to set_flash }
      it { expect(response).to redirect_to 'where_i_came_from' }
    end

    context 'when not all procedures are filled out' do
      before do
        sign_in @admin
        @reservation =
          FactoryGirl.create(:checked_out_reservation, reserver: @user)
        @procedure =
          FactoryGirl.create(:checkin_procedure,
                             equipment_model: @reservation.equipment_model)
        reservations_params =
          { @reservation.id.to_s => { notes: '', checkin?: '1',
                                      checkin_procedures: {} } }
        put :checkin, user_id: @user.id, reservations: reservations_params
      end

      it { expect(response).to be_success }
      it { is_expected.to render_template(:receipt) }

      it 'assigns empty @check_out_set' do
        expect(assigns(:check_out_set)).to be_empty
      end

      it 'populates @check_in_set' do
        expect(assigns(:check_in_set)).to eq [@reservation]
      end

      it 'updates the reservation' do
        expect(@reservation.checkin_handler).to be_nil
        expect(@reservation.checked_in).to be_nil
        @reservation.reload
        expect(@reservation.checkin_handler).to be_a(User)
        expect(@reservation.checked_in).to_not be_nil
        expect(@reservation.notes).to include(@procedure.step)
      end
    end
  end

  describe '#renew (PUT /reservations/:id/renew)' do
    # Access: Admins, checkout persons, users if it's their own reservation
    # Functionality:
    # - sets @reservation
    # - add @reservation.max_renewal_length_available.days to due_date
    # - add 1 to @reservation.times_renewed
    # - redirects to @reservation if you can't save
    # - redirects to root_path if you can save
    #     (is saving determined by equipment_model.max_renewal_times /
    #      max_renewal_length?)

    # TODO: Test circumstances under which renewal doesn't/shouldn't work

    shared_examples 'can renew reservation' do
      before(:each) do
        @reservation =
          FactoryGirl.create(:checked_out_reservation, reserver: @user)
        put :renew, id: @reservation.id
      end

      it { is_expected.to redirect_to(reservation_path(@reservation)) }

      it 'should extend due_date' do
        expect { @reservation.reload }.to change { @reservation.due_date }
      end
    end

    context 'when accessed by admin' do
      before(:each) do
        sign_in @admin
      end

      include_examples 'can renew reservation'
    end

    context 'when accessed by checkout person' do
      before(:each) do
        sign_in @checkout_person
      end

      include_examples 'can renew reservation'
    end

    context 'when accessed by patron' do
      before(:each) do
        sign_in @user
      end

      include_examples 'can renew reservation'

      context 'trying to renew someone elses reservation' do
        before do
          @other_res = FactoryGirl.create(:checked_out_reservation)
          put :renew, id: @other_res.id
        end
        it { expect(response).to be_redirect }
        it do
          expect { @other_res.reload }.not_to change { @other_res.checked_in }
        end
      end
    end

    it_behaves_like 'inaccessible by banned user' do
      before { put :renew, id: @reservation.id }
    end

    context 'when reserver is banned' do
      before(:each) do
        @reservation.update_attribute(:reserver_id, @banned.id)
        sign_in @admin
        put :renew, id: @reservation.id
      end

      it { expect { @reservation.reload }.not_to change { @reservation } }
      it { is_expected.to set_flash }
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

    # TODO: ??

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
        @reservation =
          FactoryGirl.create(:checked_out_reservation, reserver: @user)
        put :archive, id: @reservation.id
      end
    end
  end

  describe '#send_receipt (GET /reservations/:id/send_receipt)' do
    before(:each) do
      sign_in @checkout_person
    end

    context 'successfully emails' do
      before do
        @reservation.update_attributes(
          FactoryGirl.attributes_for(:checked_out_reservation))
        get :send_receipt, id: @reservation.id
      end
      it { is_expected.to redirect_to(@reservation) }
      it { should set_flash[:notice] }
    end

    context 'fails to send email' do
      before do
        allow(UserMailer).to receive_message_chain(
          'reservation_status_update.deliver').and_return(false)
        get :send_receipt, id: @reservation.id
      end
      it { is_expected.to redirect_to(@reservation) }
      it { should set_flash[:error] }
    end
  end

  describe '#review GET' do
    context 'as admin' do
      before do
        sign_in @admin
        get :review, id: @reservation.id
      end
      it 'should assign all current requests except itself' do
        expect(assigns(:all_current_requests_by_user)).to\
          eq @reservation.reserver.reservations.requested
            .reject { |r| r.id == @reservation.id }
      end
      it 'should assign errors' do
        expect(assigns(:errors)).to eq assigns(:reservation).validate
      end
    end
    context 'as checkout' do
      before do
        sign_in @checkout_person
        get :review, id: @reservation.id
      end
    end
  end

  describe '#approve_request PUT' do
    before do
      sign_in @admin
      @requested =
        FactoryGirl.create(:valid_reservation, approval_status: 'requested')
      put :approve_request, id: @requested.id
    end
    it 'should set the reservation approval status' do
      expect(assigns(:reservation).approval_status).to eq('approved')
    end
    it 'should save the reservation' do
      expect(@requested.reload.approval_status).to eq('approved')
    end
    it 'should send an email' do
      expect_email(UserMailer.reservation_status_update(@requested))
    end
    it 'should redirect to reservations path' do
      expect(response).to redirect_to(reservations_path(requested: true))
    end
  end

  describe '#deny_request PUT' do
    before do
      sign_in @admin
      @requested =
        FactoryGirl.create(:valid_reservation, approval_status: 'requested')
      put :deny_request, id: @requested.id
    end
    it 'should set the reservation approval status to deny' do
      expect(assigns(:reservation).approval_status).to eq('denied')
    end
    it 'should save the reservation' do
      expect(@requested.reload.approval_status).to eq('denied')
    end
    it 'should send an email' do
      expect_email(UserMailer.reservation_status_update(@requested))
    end
    it 'should redurect to reservations path' do
      expect(response).to redirect_to(reservations_path(requested: true))
    end
  end
end
