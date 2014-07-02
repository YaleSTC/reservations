require 'spec_helper'

describe ReservationsController do

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

    @controller.stub(:first_time_user).and_return(nil)
    @controller.stub(:current_user).and_return(@user)

    @reservation = FactoryGirl.create(:valid_reservation, reserver: @user)
  end

  ## Shared examples
  shared_examples 'cannot access page' do
    it { response.should be_redirect }
    it { should set_the_flash }
  end

  shared_examples 'inaccessible by banned user' do
    before(:each) do
      banned = FactoryGirl.build(:banned)
      @controller.stub(:current_user).and_return(banned)
      Reservation.stub(:find).and_return(FactoryGirl.build_stubbed(:reservation, reserver: banned))
    end
    include_examples 'cannot access page'
    it { should redirect_to(root_path) }
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
      it { should be_success }
      it { should render_template(:index) }

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
           eq([Reservation.send(f).uniq.sort])
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
          @controller.stub(:current_user).and_return(@admin)
          @filters.each do |trait|
            res = FactoryGirl.build(:valid_reservation, trait,
                                    reserver: [@user, @admin].sample)
            res.save(validate: false)
          end
        end
        it 'uses :upcoming as default filter' do
          get :index
          # Cannot compare objects in nested arrays directly
          assigns(:reservations_set)[0].each do |r|
            expect(Reservation.upcoming.all.map(&:id)).to include(r.id)
          end
        end

        xit 'takes all Reservations as source' do
          expect(assigns(:reservations_source)).to eq(Reservation)
        end
      end

      context 'who is not an admin' do
        before(:each) do
          @controller.stub(:current_user).and_return(@user)
          @filters.each do |trait|
            res = FactoryGirl.build(:valid_reservation, trait,
                                    reserver: [@user, @admin].sample)
            res.save(validate: false)
          end
        end

        it 'uses :reserved as the default filter' do
          get :index
          # Cannot compare objects in nested arrays directly
          assigns(:reservations_set)[0].each do |r|
            expect(@controller.current_user.reservations.upcoming.map(&:id)).to include(r.id)
         end
        end
      end
    end

    it_behaves_like 'inaccessible by banned user' do
      before { get :index }
    end
  end

  describe '#show (GET /reservations/:id)' do
    context 'when accessed by a non-banned user' do
      before(:each) do
        @controller.stub(:current_user).and_return(@user)
        Reservation.stub(:find).and_return(@reservation)
        get :show, id: 1
      end
      it { response.should be_success }
      it { should render_template(:show) }

      context 'who is an admin' do
        it 'should display own reservation'
        it 'should display anybody\'s reservation'
      end

      context 'who is not an admin' do
        it 'should display own reservation'
        it 'should not display someone else\'s reservation'
      end
    end

    it_behaves_like 'inaccessible by banned user' do
      before { get :show, id: 1 }
    end
  end

  describe '#new (GET /reservations/new)' do
    # unhappy paths: banned user, there is no reservation in the cart
    it_behaves_like 'inaccessible by banned user' do
      before { get :new }
    end

    context 'when accessed by a non-banned user' do
      before(:each) { @controller.stub(:current_user).and_return(@user) }

      context 'with an empty cart' do
        before(:each) do
          get :new
        end
        it { response.should be_redirect }
        it { should set_the_flash }
      end

      context 'with a non-empty cart' do
        before(:each) do
          cart = FactoryGirl.build(:cart_with_items, reserver_id: @user.id)
          get :new, nil, cart: cart
        end

        it 'should display errors'
        it { should render_template(:new) }
      end
    end
  end

  describe '#create (POST /reservations/create)' do
    it_behaves_like 'inaccessible by banned user' do
      before { post :create }
    end

    context 'when accessed by non-banned user' do
      before(:each) { @controller.stub(:current_user).and_return(@user) }

      context 'with validation-failing items in Cart' do
        before(:each) do
          @invalid_cart = FactoryGirl.build(:invalid_cart)
          @req = Proc.new do
            post :create,
              {reservation: {start_date: Date.today, due_date: Date.tomorrow,
                            reserver_id: @user.id}},
              {cart: @invalid_cart}
          end
        end


        context 'and user can override errors' do
          before(:each) do
            AppConfig.first.update_attributes(override_on_create: true)
            @controller.stub(:current_user).and_return(@checkout_person)
          end

          it 'affects the database' do
            expect { @req.call }.to change { Reservation.count }
          end

          it 'should redirect' do
            @req.call
            response.should redirect_to(manage_reservations_for_user_path(@user.id))
          end

          it 'sets the flash' do
            @req.call
            flash[:notice].should_not be_nil
          end
        end

        # expected to fail until ReservationController is fixed from #583
        context 'and user cannot override errors' do
          before { pending } # FIXME: Remove
          before(:each) do
            AppConfig.first.update_attributes(override_on_create: false)
            @controller.stub(:current_user).and_return(@checkout_person)
          end
          it 'does not affect database' do
            expect { @req.call }.to_not change { Reservation.count }
          end
          it 'redirects to catalog_path' do
            @req.call
            response.should redirect_to(catalog_path)
          end
          it 'sets the flash' do
            @req.call
            flash[:error].should_not be_nil
          end
        end
      end

      context 'with validation-passing items in Cart' do
        before(:each) do
          @valid_cart = FactoryGirl.build(:cart_with_items)
          @req = Proc.new do
            post :create,
              {reservation: {start_date: Date.today, due_date: Date.tomorrow,
                            reserver_id: @user.id}},
              {cart: @valid_cart}
          end
        end

        it 'saves items into database' do
          expect { @req.call }.to change { Reservation.count }
        end
        it 'empties the Cart' do
          expect { @req.call }.to change { CartReservation.count }
          response.request.env['rack.session'][:cart].items.count.should eq(0)
          # Cart.should_receive(:new)
        end
        it 'sets flash[:notice]' do
          @req.call
          flash[:notice].should_not be_nil
        end
        it 'is a redirect' do
          @req.call
          response.should be_redirect
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
        @controller.stub(:current_user).and_return(@user)
        get 'edit', id: @reservation.id
      end
      include_examples 'cannot access page'
    end

    context 'when accessed by checkout person disallowed by settings' do
      before(:each) do
        @controller.stub(:current_user).and_return(@checkout_person)
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
      it { should render_template(:edit) }
    end

    context 'when accessed by checkout person allowed by settings' do
      before(:each) do
        @controller.stub(:current_user).and_return(@checkout_person)
        AppConfig.first.update_attributes(checkout_persons_can_edit: true)
        get :edit, id: @reservation.id
      end
      include_examples 'can access edit page'
    end

    context 'when accessed by admin' do
      before(:each) do
        @controller.stub(:current_user).and_return(@admin)
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
        @controller.stub(:current_user).and_return(@user)
        put 'update', id: @reservation.id
      end
      include_examples 'cannot access page'
    end

    context 'when accessed by checkout person disallowed by settings' do
      before(:each) do
        @controller.stub(:current_user).and_return(@checkout_person)
        AppConfig.first.update_attributes(checkout_persons_can_edit: false)
        put 'update', {id: @reservation.id, reservation: FactoryGirl.attributes_for(:reservation)}
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
              start_date: Date.today.strftime('%m/%d/%Y'),
              due_date: (Date.tomorrow + 3.days).strftime('%m/%d/%Y')),
            equipment_object: ''}
        end
        it 'should update the reservation details' do
          @reservation.reload
          expect(@reservation.start_date).to eq(Date.today.to_time)
          expect(@reservation.due_date).to eq((Date.tomorrow + 3.days).to_time)
        end
        it { should redirect_to(@reservation) }
      end

      describe 'and provides valid params[:equipment_object]' do
        before(:each) do
          @new_equipment_object = FactoryGirl.create(:equipment_object, equipment_model: @reservation.equipment_model)
          put :update, { id: @reservation.id,
            reservation: FactoryGirl.attributes_for(:reservation,
              start_date: Date.today.strftime('%m/%d/%Y'),
              due_date: Date.tomorrow.strftime('%m/%d/%Y')),
            equipment_object: @new_equipment_object.id }
        end
        it 'should update the object on current reservation' do
          expect{ @reservation.reload }.to change{@reservation.equipment_object}
        end
        it { should redirect_to(@reservation) }
      end

      # Unhappy path
      describe 'and provides invalid params[:reservation]' do
        before(:each) do
          request.env["HTTP_REFERER"] = reservation_path(@reservation)
          put :update, { id: @reservation.id,
            reservation: FactoryGirl.attributes_for(:reservation,
              start_date: Date.today.strftime('%m/%d/%Y'),
              due_date: Date.yesterday.strftime('%m/%d/%Y')),
            equipment_object: ''}
        end
        include_examples 'cannot access page'
      end
    end

    context 'when accessed by checkout person allowed by settings' do
      before(:each) do
        @controller.stub(:current_user).and_return(@checkout_person)
        AppConfig.first.update_attributes(checkout_persons_can_edit: true)
      end
      include_examples 'can access update page'
    end

    context 'when accessed by admin' do
      before(:each) do
        @controller.stub(:current_user).and_return(@admin)
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
        response.should redirect_to(reservations_url)
      end

      it 'sets the flash' do
        delete :destroy, id: reservation.id
        flash[:notice].should_not be_nil
      end
    end

    # Requires a block to be passed which defines let(:reservation)
    shared_examples 'cannot destroy reservation' do
      before(:each) { delete :destroy, id: reservation.id }
      include_examples 'cannot access page'
    end

    context 'when accessed by admin' do
      before(:each) do
        @controller.stub(:current_user).and_return(@admin)
      end

      include_examples 'can destroy reservation' do
        let!(:reservation) { FactoryGirl.create(:reservation, reserver: @user) }
      end
    end

    context 'when accessed by checkout person' do
      before(:each) do
        @controller.stub(:current_user).and_return(@checkout_person)
      end

      context 'and the reservation is checked out' do
        include_examples 'cannot destroy reservation' do
          let(:reservation) { FactoryGirl.create(:checked_out_reservation, reserver: @user) }
        end
      end

      context 'and the reservation is not checked out' do
        include_examples 'can destroy reservation' do
          let!(:reservation) { FactoryGirl.create(:reservation, reserver: @user) }
        end
      end
    end

    context 'when accessed by patron' do
      before(:each) do
        @controller.stub(:current_user).and_return(@user)
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
          let(:reservation) { FactoryGirl.create(:reservation, reserver: @checkout_person) }
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
      it { response.should be_success }
      it { should render_template(:manage) }

      it 'assigns @user correctly' do
        expect(assigns(:user)).to eq(@user)
      end

      it 'assigns @check_out_set correctly' do
        expect(assigns(:check_out_set)).to eq(Reservation.due_for_checkout(@user))
      end

      it 'assigns @check_in_set correctly' do
        expect(assigns(:check_in_set)).to eq(Reservation.due_for_checkin(@user))
      end
    end

    context 'when accessed by admin' do
      before(:each) do
        @controller.stub(:current_user).and_return(@admin)
      end

      include_examples 'can access #manage'
    end

    context 'when accessed by checkout person' do
      before(:each) do
        @controller.stub(:current_user).and_return(@checkout_person)
      end

      include_examples 'can access #manage'
    end

    context 'when accessed by patron' do
      before(:each) do
        @controller.stub(:current_user).and_return(@user)
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
      it { response.should be_success }
      it { should render_template(:current_reservations) }

      it 'assigns @user correctly' do
        expect(assigns(:user)).to eq(@user)
      end

      it 'assigns @user_overdue_reservations_set correctly' do
        expect(assigns(:user_overdue_reservations_set)).to eq [Reservation.overdue_user_reservations(@user)].delete_if{|a| a.empty?}
      end

      it 'assigns @user_checked_out_today_reservations_set correctly' do
        expect(assigns(:user_checked_out_today_reservations_set)).to eq [Reservation.checked_out_today_user_reservations(@user)].delete_if{|a| a.empty?}
      end

      it 'assigns @user_checked_out_previous_reservations_set correctly' do
        expect(assigns(:user_checked_out_previous_reservations_set)).to eq [Reservation.checked_out_previous_user_reservations(@user)].delete_if{|a| a.empty?}
      end

      it 'assigns @user_reserved_reservations_set correctly' do
        expect(assigns(:user_reserved_reservations_set)).to eq [Reservation.reserved_user_reservations(@user)].delete_if{|a| a.empty?}
      end
    end

    context 'when accessed by admin' do
      before(:each) do
        @controller.stub(:current_user).and_return(@admin)
      end

      include_examples 'can access #current'
    end

    context 'when accessed by checkout person' do
      before(:each) do
        @controller.stub(:current_user).and_return(@checkout_person)
      end

      include_examples 'can access #current'
    end

    context 'when accessed by patron' do
      before(:each) do
        @controller.stub(:current_user).and_return(@user)
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
    # - processes all reservations in params[:reservations] -- adds checkout_handler, checked_out (time), equipment_object; updates notes
    # - stops checkout if user has overdue reservations
    # - stops checkout if no reservations are selected
    # - overrides errors if you can and if there are some, otherwise redirects away
    # - sets empty @check_in_set, populates @check_out_set with the reservations
    # - renders :receipt template
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
  end

  describe '#renew (PUT /reservations/renew)' do
  end

  describe '#checkout_email (GET reservations/checkout_email)' do
    pending 'E-mails get sent'
  end

  describe '#checkin_email (GET reservations/checkin_email)' do
    pending 'E-mails get sent'
  end
end