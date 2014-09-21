require 'spec_helper'

describe ReservationsController, :type => :controller do

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
    EquipmentObject.delete_all
  end

  before(:each) do
    @cart = FactoryGirl.build(:cart, reserver_id: @user.id)

    allow(@controller).to receive(:first_time_user).and_return(nil)
    allow(@controller).to receive(:current_user).and_return(@user)

    @reservation = FactoryGirl.create(:valid_reservation, reserver: @user)
  end

  ## Shared examples
  shared_examples 'cannot access page' do
    it { expect(response).to be_redirect }
    it { is_expected.to set_the_flash }
  end

  shared_examples 'inaccessible by banned user' do
    before(:each) do
      banned = FactoryGirl.build(:banned)
      allow(@controller).to receive(:current_user).and_return(banned)
      allow(Reservation).to receive(:find).and_return(FactoryGirl.build_stubbed(:reservation, reserver: banned))
    end
    include_examples 'cannot access page'
    it { is_expected.to redirect_to(root_path) }
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
          expect(assigns(:reservations_set).uniq.sort).to \
           eq(Reservation.send(f).uniq.sort)
        end
      end

      it 'passes @default as false if valid params[filter] is provided' do
        get :index, reserved: true
        expect(assigns(:default)).to eq(false)
      end

      it 'passes @default as true if valid params[filter] is not provided' do
        get :index
        expect(assigns(:default)).to eq(true)
      end

      it 'passes @default as true if invalid params[filter] is provided' do
        get :index, absurd_and_nonexistent: true
        expect(assigns(:default)).to eq(true)
      end

      context 'who is an admin' do
        before(:each) do
          allow(@controller).to receive(:current_user).and_return(@admin)
          @filters.each do |trait|
            res = FactoryGirl.build(:valid_reservation, trait,
                                    reserver: [@user, @admin].sample)
            res.save(validate: false)
          end
        end
        it 'uses :upcoming as default filter' do
          get :index
          expect(assigns(:reservations_set) - Reservation.upcoming.all).to be_empty
        end
      end

      context 'who is not an admin' do
        before(:each) do
          allow(@controller).to receive(:current_user).and_return(@user)
          @filters.each do |trait|
            res = FactoryGirl.build(:valid_reservation, trait,
                                    reserver: [@user,@admin].sample)
            res.save(validate: false)
          end
        end

        it 'uses :reserved as the default filter' do
          get :index
          expect(assigns(:reservations_set) - @user.reservations.reserved).to be_empty
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
        allow(@controller).to receive(:current_user).and_return(@admin)
      end

      it_behaves_like 'can view reservation by patron'
      it_behaves_like 'can view reservation by admin'
    end

    context 'when accessed by checkout person' do
      before(:each) do
        allow(@controller).to receive(:current_user).and_return(@checkout_person)
      end

      it_behaves_like 'can view reservation by patron'
      it_behaves_like 'can view reservation by admin'
    end

    context 'when accessed by patron' do
      before(:each) do
        allow(@controller).to receive(:current_user).and_return(@user)
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
      before(:each) { allow(@controller).to receive(:current_user).and_return(@user) }

      context 'with an empty cart' do
        before(:each) do
          get :new
        end
        it { expect(response).to be_redirect }
        it { is_expected.to set_the_flash }
      end

      context 'with a non-empty cart' do
        before(:each) do
          cart = FactoryGirl.build(:cart_with_items, reserver_id: @user.id)
          get :new, nil, cart: cart
        end

        it 'should display errors'
        it { is_expected.to render_template(:new) }
      end
    end
  end

  describe '#create (POST /reservations/create)' do
    it_behaves_like 'inaccessible by banned user' do
      before { post :create, reservation: FactoryGirl.attributes_for(:valid_reservation) }
    end

    context 'when accessed by non-banned user' do
      before(:each) { allow(@controller).to receive(:current_user).and_return(@user) }

      context 'with validation-failing items in Cart' do
        before(:each) do
          @invalid_cart = FactoryGirl.build(:invalid_cart, reserver_id: @user.id)
          @req = Proc.new do
            post :create,
              {reservation: {notes: "because I can" }},
              {cart: @invalid_cart}
          end
          @req_no_notes = Proc.new do
            post :create,
              { reservation: {notes: "" } },
              { cart: @invalid_cart }
          end
        end

        context 'no justification provided' do
          before do
            allow(@controller).to receive(:current_user).and_return(@checkout_person)
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
            allow(@controller).to receive(:current_user).and_return(@checkout_person)
          end

          it 'affects the database' do
            expect { @req.call }.to change { Reservation.count }
          end

          it 'should redirect' do
            @req.call
            expect(response).to redirect_to(manage_reservations_for_user_path(@user.id))
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
            allow(@controller).to receive(:current_user).and_return(@checkout_person)
          end
          it 'affects database' do
            expect { @req.call }.to change { Reservation.count }
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
          @req = Proc.new do
            post :create,
              {reservation: {start_date: Date.current, due_date: Date.tomorrow,
                            reserver_id: @user.id}},
              {cart: @valid_cart}
          end
        end

        it 'saves items into database' do
          expect { @req.call }.to change { Reservation.count }
        end
        it 'empties the Cart' do
          @req.call
          expect(response.request.env['rack.session'][:cart].items.count).to eq(0)
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
    end
  end

  describe '#edit (GET /reservations/:id/edit)' do
    ## Unhappy paths
    it_behaves_like 'inaccessible by banned user' do
      before { get 'edit', id: @reservation.id }
    end

    context 'when accessed by patron' do
      before(:each) do
        allow(@controller).to receive(:current_user).and_return(@user)
        get 'edit', id: @reservation.id
      end
      include_examples 'cannot access page'
    end

    context 'when accessed by checkout person disallowed by settings' do
      before(:each) do
        allow(@controller).to receive(:current_user).and_return(@checkout_person)
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
        expect(assigns(:option_array)).to eq @reservation.equipment_model.equipment_objects.collect { |e| [e.name, e.id] }
      end
      it { is_expected.to render_template(:edit) }
    end

    context 'when accessed by checkout person allowed by settings' do
      before(:each) do
        allow(@controller).to receive(:current_user).and_return(@checkout_person)
        AppConfig.first.update_attributes(checkout_persons_can_edit: true)
        get :edit, id: @reservation.id
      end
      include_examples 'can access edit page'
    end

    context 'when accessed by admin' do
      before(:each) do
        allow(@controller).to receive(:current_user).and_return(@admin)
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
    # - check due_date > start_date from params; if not, flash error and redirect back
    # - if params[:equipment_object] is defined, swap the object from the current reservation
    # - affect the current reservation (@reservation)
    # - set flash notice
    # - redirect to @reservation
    # Expects in params:
    # - params[:equipment_object] = id of equipment object or nil
    # - params[:reservation] with :start_date, :due_date, :reserver_id, :notes

    ## Unhappy paths due to authorization
    it_behaves_like 'inaccessible by banned user' do
      before { put :update }
    end

    context 'when accessed by patron' do
      before(:each) do
        allow(@controller).to receive(:current_user).and_return(@user)
        put 'update', id: @reservation.id
      end
      include_examples 'cannot access page'
    end

    context 'when accessed by checkout person disallowed by settings' do
      before(:each) do
        allow(@controller).to receive(:current_user).and_return(@checkout_person)
        AppConfig.first.update_attributes(checkout_persons_can_edit: false)
        put 'update', id: @reservation.id, reservation: FactoryGirl.attributes_for(:reservation)
      end
      include_examples 'cannot access page'
    end

    ## Happy paths due to authorization
    shared_examples 'can access update page' do
      # Happy paths
      describe 'and provides valid params[:reservation]' do
        before(:each) do
          put :update, { id: @reservation.id,
            reservation: FactoryGirl.attributes_for(:reservation,
              start_date: Date.current,
              due_date: (Date.tomorrow + 3.days)),
            equipment_object: ''}
        end
        it 'should update the reservation details' do
          @reservation.reload
          expect(@reservation.start_date.to_time.utc).to eq(Time.current.midnight.utc)
          expect(@reservation.due_date.to_time.utc).to eq((Time.current.midnight + 4*24.hours).utc)
        end
        it { is_expected.to redirect_to(@reservation) }
      end

      describe 'and provides valid params[:equipment_object]' do
        before(:each) do
          @new_equipment_object = FactoryGirl.create(:equipment_object, equipment_model: @reservation.equipment_model)
          put :update, { id: @reservation.id,
            reservation: FactoryGirl.attributes_for(:reservation,
              start_date: Date.current,
              due_date: Date.tomorrow),
            equipment_object: @new_equipment_object.id }
        end
        it 'should update the object on current reservation' do
          expect{ @reservation.reload }.to change{@reservation.equipment_object}
        end
        it { is_expected.to redirect_to(@reservation) }
      end

      # Unhappy path
      describe 'and provides invalid params[:reservation]' do
        before(:each) do
          request.env["HTTP_REFERER"] = reservation_path(@reservation)
          put :update, { id: @reservation.id,
            reservation: FactoryGirl.attributes_for(:reservation,
              start_date: Date.current,
              due_date: Date.yesterday),
            equipment_object: ''}
        end
        include_examples 'cannot access page'
      end
    end

    context 'when accessed by checkout person allowed by settings' do
      before(:each) do
        allow(@controller).to receive(:current_user).and_return(@checkout_person)
        AppConfig.first.update_attributes(checkout_persons_can_edit: true)
      end
      include_examples 'can access update page'
    end

    context 'when accessed by admin' do
      before(:each) do
        allow(@controller).to receive(:current_user).and_return(@admin)
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
        expect { delete :destroy, id: reservation.id }.to change { Reservation.count }
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
        allow(@controller).to receive(:current_user).and_return(@admin)
      end

      include_examples 'can destroy reservation' do
        let!(:reservation) { FactoryGirl.create(:valid_reservation, reserver: @user) }
      end
    end

    context 'when accessed by checkout person' do
      before(:each) do
        allow(@controller).to receive(:current_user).and_return(@checkout_person)
      end

      context 'and the reservation is checked out' do
        include_examples 'cannot destroy reservation' do
          let(:reservation) { FactoryGirl.create(:checked_out_reservation, reserver: @user) }
        end
      end

      context 'and the reservation is not checked out' do
        include_examples 'can destroy reservation' do
          let!(:reservation) { FactoryGirl.create(:valid_reservation, reserver: @user) }
        end
      end
    end

    context 'when accessed by patron' do
      before(:each) do
        allow(@controller).to receive(:current_user).and_return(@user)
      end

      context 'and the reservation is their own' do
        context 'and it is checked out' do
          include_examples 'cannot destroy reservation' do
            let(:reservation) { FactoryGirl.create(:checked_out_reservation, reserver: @user) }
          end

        end

        context 'and it is not checked out' do
          include_examples 'can destroy reservation' do
            let!(:reservation) { FactoryGirl.create(:valid_reservation, reserver: @user) }
          end
        end
      end

      context 'and the reservation is not their own' do
        include_examples 'cannot destroy reservation' do
          let(:reservation) { FactoryGirl.create(:valid_reservation, reserver: @checkout_person) }
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
        allow(@controller).to receive(:current_user).and_return(@admin)
      end

      include_examples 'can access #manage'
    end

    context 'when accessed by checkout person' do
      before(:each) do
        allow(@controller).to receive(:current_user).and_return(@checkout_person)
      end

      include_examples 'can access #manage'
    end

    context 'when accessed by patron' do
      before(:each) do
        allow(@controller).to receive(:current_user).and_return(@user)
        get :manage, user_id: @user.id
      end

      include_examples 'cannot access page'
    end

    it_behaves_like 'inaccessible by banned user' do
      before { get :manage, user_id: @banned.id }
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
        expect(assigns(:user_overdue_reservations_set)).to eq [Reservation.overdue.for_reserver(@user)].delete_if{|a| a.empty?}
      end

      it 'assigns @user_checked_out_today_reservations_set correctly' do
        expect(assigns(:user_checked_out_today_reservations_set)).to eq [Reservation.checked_out_today.for_reserver(@user)].delete_if{|a| a.empty?}
      end

      it 'assigns @user_checked_out_previous_reservations_set correctly' do
        expect(assigns(:user_checked_out_previous_reservations_set)).to eq [Reservation.checked_out_previous.for_reserver(@user)].delete_if{|a| a.empty?}
      end

      it 'assigns @user_reserved_reservations_set correctly' do
        expect(assigns(:user_reserved_reservations_set)).to eq [Reservation.reserved.for_reserver(@user)].delete_if{|a| a.empty?}
      end
    end

    context 'when accessed by admin' do
      before(:each) do
        allow(@controller).to receive(:current_user).and_return(@admin)
      end

      include_examples 'can access #current'
    end

    context 'when accessed by checkout person' do
      before(:each) do
        allow(@controller).to receive(:current_user).and_return(@checkout_person)
      end

      include_examples 'can access #current'
    end

    context 'when accessed by patron' do
      before(:each) do
        allow(@controller).to receive(:current_user).and_return(@user)
        get :current, user_id: @user.id
      end

      include_examples 'cannot access page'
    end

    it_behaves_like 'inaccessible by banned user' do
      before { get :current, user_id: @banned.id }
    end
  end

  describe '#checkout (PUT /reservations/checkout/:user_id)' do
    # Access: Admins, checkout persons.
    # Functionality: very complicated (almost 100 lines)
    # - pass TOS (if not, redirect)
    # - params[:reservations] contains hash of
    #    {reservation_id => {equipment_object_id: int, notes: str,
    #      checkout_precedures: {checkout_procedure_id => int}}}
    # - stops checkout if user has overdue reservations
    # - stops checkout if no reservations are selected
    # - overrides errors if you can and if there are some, otherwise redirects away

    # Effects if successful:
    # - sets empty @check_in_set, populates @check_out_set with the reservations
    # - processes all reservations in params[:reservations] -- adds checkout_handler, checked_out (time), equipment_object; updates notes
    # - renders :receipt template

    # Note: Many of these can be cross-applied to #checkin as well

    shared_examples 'has successful checkout' do
      before(:each) do
        @obj = FactoryGirl.create(:equipment_object, equipment_model: @reservation.equipment_model)
        reservations_params = {@reservation.id.to_s => {notes: "", equipment_object_id: @obj.id}}
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
        expect(@reservation.equipment_object).to be_nil
        @reservation.reload
        expect(@reservation.checkout_handler).to be_a(User)
        expect(@reservation.checked_out).to_not be_nil
        expect(@reservation.equipment_object).to eq @obj
      end
    end

    context 'when accessed by admin' do
      before(:each) do
        allow(@controller).to receive(:current_user).and_return(@admin)
      end

      include_examples 'has successful checkout'
    end

    context 'when accessed by checkout person' do
      before(:each) do
        allow(@controller).to receive(:current_user).and_return(@checkout_person)
      end

      include_examples 'has successful checkout'
    end

    context 'when accessed by patron' do
      before(:each) do
        allow(@controller).to receive(:current_user).and_return(@user)
        put :checkout, user_id: @user.id
      end

      include_examples 'cannot access page'
    end

    it_behaves_like 'inaccessible by banned user' do
      before { put :checkout, user_id: @banned.id }
    end

    context 'when tos returns false' do
      before do
        allow(@controller).to receive(:check_tos).and_return(false)
        put :checkout
      end
      it { expect(response).to be_redirect }
    end

    context 'when not all procedures are filled out' do
      before do
        allow(@controller).to receive(:current_user).and_return(@admin)
        @obj = FactoryGirl.create(:equipment_object, equipment_model: @reservation.equipment_model)
        @procedure = FactoryGirl.create(:checkout_procedure, equipment_model: @reservation.equipment_model)
        reservations_params = {@reservation.id.to_s => {notes: "", equipment_object_id: @obj.id, checkout_procedures: {}}}
        put :checkout, user_id: @user.id,  reservations: reservations_params
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
        expect(@reservation.equipment_object).to be_nil
        @reservation.reload
        expect(@reservation.checkout_handler).to be_a(User)
        expect(@reservation.checked_out).to_not be_nil
        expect(@reservation.equipment_object).to eq @obj
        expect(@reservation.notes).to include(@procedure.step)
      end
    end

    context 'no reservations selected' do
      before(:each) do
        reservations_params = {}
        put :checkout, user_id: @user.id, reservations: reservations_params
      end
      it { is_expected.to set_the_flash }
      it { expect(response).to be_redirect }
    end

    context 'reserver has overdue reservations' do

      context 'can override reservations?' do
        before do
          allow(@controller).to receive(:current_user).and_return(@admin)
          @obj = FactoryGirl.create(:equipment_object, equipment_model: @reservation.equipment_model)
          reservations_params = {@reservation.id.to_s => {notes: "", equipment_object_id: @obj.id }}
          overdue = FactoryGirl.build(:overdue_reservation, reserver_id: @user.id)
          overdue.save(validate: false)
          put :checkout, user_id: @user.id, reservations: reservations_params
        end
        it { expect(response).to be_success }
        it { is_expected.to render_template(:receipt) }
      end
      context 'cannot override' do
        before do
          allow(@controller).to receive(:current_user).and_return(@user)
          @obj = FactoryGirl.create(:equipment_object, equipment_model: @reservation.equipment_model)
          reservations_params = {@reservation.id.to_s => {notes: "", equipment_object_id: @obj.id }}
          overdue = FactoryGirl.build(:overdue_reservation, reserver_id: @user.id)
          overdue.save(validate: false)
          put :checkout, user_id: @user.id, reservations: reservations_params
        end
        it { is_expected.to set_the_flash }
        it { expect(response).to be_redirect }
      end

    end

  end

  describe '#checkin (PUT /reservations/check-in/:user_id)' do
    # Access: Admins, checkout persons.
    # Functionality: very complicated (almost 80 lines)
    # - params[:reservations] contains a hash of
    #    {reservation_id => {checkin?: int, notes: str,
    #      (nil?) checkin_procedures: {checkin_procedure_id => int}}}
    # - processes all reservations in params[:reservations] -- adds checkin_handler, checked_in (time); updates notes
    # - stops checkin if no reservations are selected
    # - overrides errors if you can and if there are some, otherwise redirects away
    # - renders :receipt template

    shared_examples 'has successful checkin' do
      before(:each) do
        @reservation = FactoryGirl.create(:checked_out_reservation, reserver: @user)
        reservations_params = {@reservation.id.to_s => {notes: "", checkin?: "1"}}
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
    end

    context 'when accessed by admin' do
      before(:each) do
        allow(@controller).to receive(:current_user).and_return(@admin)
      end

      include_examples 'has successful checkin'
    end

    context 'when accessed by checkout person' do
      before(:each) do
        allow(@controller).to receive(:current_user).and_return(@checkout_person)
      end

      include_examples 'has successful checkin'
    end

    context 'when accessed by patron' do
      before(:each) do
        allow(@controller).to receive(:current_user).and_return(@user)
        put :checkin, user_id: @user.id
      end

      include_examples 'cannot access page'
    end

    it_behaves_like 'inaccessible by banned user' do
      before { put :checkin, user_id: @banned.id }
    end

    context 'items have already been checked in' do
      before do
        allow(@controller).to receive(:current_user).and_return(@admin)
        request.env["HTTP_REFERER"] = 'where_i_came_from'
        @reservation = FactoryGirl.build(:checked_in_reservation, reserver: @user)
        @reservation.save(validate: false)
        reservations_params = {@reservation.id.to_s => {notes: "", checkin?: "1"}}
        put :checkin, user_id: @user.id, reservations: reservations_params
      end

      it { is_expected.to set_the_flash }
      it { expect(response).to be_redirect }
    end

    context 'no reservations to check in' do
      before do
        request.env["HTTP_REFERER"] = 'where_i_came_from'
        allow(@controller).to receive(:current_user).and_return(@admin)
        put :checkin,  user_id: @user.id, reservations: {}
      end
      it { is_expected.to set_the_flash }
      it { expect(response).to be_redirect }
    end

    context 'when not all procedures are filled out' do
      before do
        allow(@controller).to receive(:current_user).and_return(@admin)
        @reservation = FactoryGirl.create(:checked_out_reservation, reserver: @user)
        @procedure = FactoryGirl.create(:checkin_procedure, equipment_model: @reservation.equipment_model)
        reservations_params = {@reservation.id.to_s => {notes: "", checkin?: "1", checkin_procedures: {}}}
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
    #     (is saving determined by equipment_model.max_renewal_times / max_renewal_length?)

    # TODO: Test circumstances under which renewal doesn't/shouldn't work

    shared_examples 'can renew reservation' do
      before(:each) do
        @reservation = FactoryGirl.create(:checked_out_reservation, reserver: @user)
        put :renew, id: @reservation.id
      end

      it { is_expected.to redirect_to(root_path) }

      it 'should extend due_date' do
        expect { @reservation.reload }.to change { @reservation.due_date }
      end
    end

    context 'when accessed by admin' do
      before(:each) do
        allow(@controller).to receive(:current_user).and_return(@admin)
      end

      include_examples 'can renew reservation'
    end

    context 'when accessed by checkout person' do
      before(:each) do
        allow(@controller).to receive(:current_user).and_return(@checkout_person)
      end

      include_examples 'can renew reservation'
    end

    context 'when accessed by patron' do
      before(:each) do
        allow(@controller).to receive(:current_user).and_return(@user)
      end

      include_examples 'can renew reservation'

      context 'trying to renew someone elses reservation' do
        before do
          @other_res = FactoryGirl.create(:checked_out_reservation)
          put :renew, id: @other_res.id
        end
        it { expect(response).to be_redirect }
        it { expect { @other_res.reload }.not_to change { @other_res.checked_in } }
      end

    end

    it_behaves_like 'inaccessible by banned user' do
      before { put :renew, id: @reservation.id }
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

    # TODO:

    shared_examples 'cannot archive reservation' do
      before do
        request.env["HTTP_REFERER"] = reservation_path(@reservation)
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
        @reservation = FactoryGirl.create(:checked_out_reservation, reserver: @user)
        request.env["HTTP_REFERER"] = reservation_path(@reservation)
      end

      context 'when accessed by admin' do
        before(:each) do
          allow(@controller).to receive(:current_user).and_return(@admin)
        end

        context 'with archive note' do
          before(:each) do
            put :archive, id: @reservation.id, archive_note: "Because I can"
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
          allow(@controller).to receive(:current_user).and_return(@checkout_person)
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
        @reservation = FactoryGirl.build(:checked_in_reservation, reserver: @user)
        @reservation.save(validate: false)
        request.env["HTTP_REFERER"] = reservation_path(@reservation)
        put :archive, id: @reservation.id, archive_note: "Because I can"
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
        @reservation = FactoryGirl.create(:checked_out_reservation, reserver: @user)
        put :archive, id: @reservation.id
      end
    end
  end

  describe '#checkout_email (GET reservations/checkout_email)' do
    pending 'E-mails get sent'
  end

  describe '#checkin_email (GET reservations/checkin_email)' do
    pending 'E-mails get sent'
  end
end
