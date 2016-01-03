require 'spec_helper'

describe 'Reservations', type: :feature do
  context 'can be created' do
    before(:each) { empty_cart }

    shared_examples 'can create valid reservation' do |reserver|
      let(:reserver) { reserver }
      str = reserver ? 'for other user successfully' : 'successfully'

      it str do
        visit root_path
        change_reserver(reserver) if reserver
        add_item_to_cart(@eq_model)
        update_cart_start_date(Time.zone.today)
        due_date = Time.zone.today + 1.day
        update_cart_due_date(due_date)
        # request catalog since our update cart methods only return the cart
        # partial from the JS update (so the 'Reserve' link wouldn't be there)
        visit root_path
        click_link 'Reserve', href: new_reservation_path

        # set reserver to current user if unset, check confirmation page
        reserver = reserver ? reserver : @current_user
        expect(page).to have_content reserver.name
        expect(page).to have_content Time.zone.today.to_s(:long)
        expect(page).to have_content due_date.to_s(:long)
        expect(page).to have_content @eq_model.name
        expect(page).to have_content 'Create Reservation'
        click_button 'Finalize Reservation'

        # check that reservation was created with correct dates
        query = Reservation.for_eq_model(@eq_model).for_reserver(reserver.id)
        expect(query.count).to eq(1)
        expect(query.first.start_date).to eq(Time.zone.today)
        expect(query.first.due_date).to eq(due_date)
        expect(query.first.status).to eq('reserved')
      end
    end

    shared_examples 'can create reservation request' do |reserver|
      let(:reserver) { reserver }
      str = reserver ? 'for other user successfully' : 'successfully'

      it str do
        visit root_path
        change_reserver(reserver) if reserver
        add_item_to_cart(@eq_model)
        update_cart_start_date(Time.zone.today)
        # violate length validation
        bad_due_date =
          Time.zone.today + (@eq_model.maximum_checkout_length + 1).days
        update_cart_due_date(bad_due_date)
        # request catalog since our update cart methods only return the cart
        # partial from the JS update (so the 'Reserve' link wouldn't be there)
        visit root_path
        click_link 'Reserve', href: new_reservation_path

        # set reserver to current user if unset, check confirmation page
        reserver = reserver ? reserver : @current_user
        expect(page).to have_content reserver.name
        expect(page).to have_content Time.zone.today.to_s(:long)
        expect(page).to have_content bad_due_date.to_s(:long)
        expect(page).to have_content @eq_model.name
        expect(page).to have_content 'File Reservation Request'
        find(:xpath, "//textarea[@id='reservation_notes']").set 'Because'
        click_button 'Submit Request'

        # check that reservation request was created with correct dates
        query = Reservation.for_eq_model(@eq_model).for_reserver(reserver.id)
        expect(query.count).to eq(1)
        expect(query.first.start_date).to eq(Time.zone.today)
        expect(query.first.due_date).to eq(bad_due_date)
        expect(query.first.status).to eq('requested')
      end
    end

    shared_examples 'can create failing reservation' do |reserver|
      let(:reserver) { reserver }
      str = reserver ? 'for other user successfully' : 'successfully'

      it str do
        visit root_path
        change_reserver(reserver) if reserver
        add_item_to_cart(@eq_model)
        update_cart_start_date(Time.zone.today)
        # violate length validation
        bad_due_date =
          Time.zone.today + (@eq_model.maximum_checkout_length + 1).days
        update_cart_due_date(bad_due_date)
        # request catalog since our update cart methods only return the cart
        # partial from the JS update (so the 'Reserve' link wouldn't be there)
        visit root_path
        click_link 'Reserve', href: new_reservation_path

        # set reserver to current user if unset, check confirmation page
        reserver = reserver ? reserver : @current_user
        expect(page).to have_content reserver.name
        expect(page).to have_content Time.zone.today.to_s(:long)
        expect(page).to have_content bad_due_date.to_s(:long)
        expect(page).to have_content @eq_model.name
        expect(page).to have_content 'Create Reservation'
        expect(page).to have_content 'Please be aware of the following errors:'
        find(:xpath, "//textarea[@id='reservation_notes']").set 'Because'
        click_button 'Finalize Reservation'

        # check that reservation was created with correct dates
        query = Reservation.for_eq_model(@eq_model).for_reserver(reserver.id)
        expect(query.count).to eq(1)
        expect(query.first.start_date).to eq(Time.zone.today)
        expect(query.first.due_date).to eq(bad_due_date)
        expect(query.first.status).to eq('reserved')
      end
    end

    context 'by patrons' do
      before { sign_in_as_user(@user) }
      after { sign_out }

      it_behaves_like 'can create valid reservation'
      it_behaves_like 'can create reservation request'
    end

    context 'by checkout persons' do
      before { sign_in_as_user(@checkout_person) }
      after { sign_out }

      context 'without override permissions' do
        before { AppConfig.first.update_attributes(override_on_create: false) }

        it_behaves_like 'can create valid reservation', @user
        it_behaves_like 'can create reservation request', @user
      end

      context 'with override permissions' do
        before { AppConfig.first.update_attributes(override_on_create: true) }

        it_behaves_like 'can create failing reservation', @user
      end
    end

    context 'by admins' do
      before { sign_in_as_user(@admin) }
      after { sign_out }

      context 'with override disabled' do
        before { AppConfig.first.update_attributes(override_on_create: false) }

        it_behaves_like 'can create valid reservation', @user
        it_behaves_like 'can create failing reservation', @user
      end

      context 'with override enabled' do
        before { AppConfig.first.update_attributes(override_on_create: true) }

        it_behaves_like 'can create failing reservation', @user
      end
    end

    context 'by superusers' do
      before { sign_in_as_user(@superuser) }
      after { sign_out }

      context 'with override disabled' do
        before { AppConfig.first.update_attributes(override_on_create: false) }

        it_behaves_like 'can create valid reservation', @user
        it_behaves_like 'can create failing reservation', @user
      end

      context 'with override enabled' do
        before { AppConfig.first.update_attributes(override_on_create: true) }

        it_behaves_like 'can create failing reservation', @user
      end
    end
  end

  context 'banned equipment processing' do
    after(:each) do
      @user.update_attributes(role: 'normal')
    end
    shared_examples 'can handle banned user reservation transactions' do
      it 'checks in successfully' do
        # check in
        @checked_out_res = FactoryGirl.create :checked_out_reservation,
                                              reserver: @user,
                                              equipment_model: @eq_model
        @user.update_attributes(role: 'banned')
        visit manage_reservations_for_user_path(@user)
        check "#{@checked_out_res.equipment_item.name}"
        click_button 'Check-In Equipment'

        expect(page).to have_content 'Check-In Receipt'
        expect(page).to have_content current_user.name
        @checked_out_res.reload
        expect(@checked_out_res.checkin_handler).to eq(current_user)
        expect(@checked_out_res.checked_in).not_to be_nil
      end
      it 'cannot checkout successfully' do
        @res = FactoryGirl.create :valid_reservation, reserver: @user,
                                                      equipment_model: @eq_model
        @user.update_attributes(role: 'banned')
        # check out
        visit manage_reservations_for_user_path(@user)
        select "#{@eq_model.equipment_items.first.name}", from: 'Equipment Item'
        click_button 'Check-Out Equipment'
        expect(page).to have_content 'Banned users cannot check out equipment'
      end
    end

    context 'as checkout person' do
      before { sign_in_as_user(@checkout_person) }
      after { sign_out }

      it_behaves_like 'can handle banned user reservation transactions'
    end

    context 'as admin' do
      before { sign_in_as_user(@admin) }
      after { sign_out }

      it_behaves_like 'can handle banned user reservation transactions'
    end

    context 'as superuser' do
      before { sign_in_as_user(@superuser) }
      after { sign_out }

      it_behaves_like 'can handle banned user reservation transactions'
    end
  end

  context 'equipment processing' do
    before(:each) do
      @res = FactoryGirl.create :valid_reservation, reserver: @user,
                                                    equipment_model: @eq_model
      visit manage_reservations_for_user_path(@user)
    end

    shared_examples 'can handle reservation transactions' do
      it 'checks out and checks in successfully' do
        # check out
        visit manage_reservations_for_user_path(@user)
        select "#{@eq_model.equipment_items.first.name}", from: 'Equipment Item'
        click_button 'Check-Out Equipment'

        expect(page).to have_content 'Check-Out Receipt'
        expect(page).to have_content current_user.name
        @res.reload
        expect(@res.equipment_item_id).to eq(@eq_model.equipment_items.first.id)
        expect(@res.checkout_handler).to eq(current_user)
        expect(@res.checked_out).not_to be_nil
        # check equipment item notes if admin or superuser (checkout persons
        # can't see them)
        if current_user.view_mode == 'admin' ||
           current_user.view_mode == 'superuser'
          visit equipment_item_path(@res.equipment_item)
          expect(page).to have_link('Checked out', href: resource_url(@res))
        end

        # check in
        visit manage_reservations_for_user_path(@user)
        check "#{@res.equipment_item.name}"
        click_button 'Check-In Equipment'

        expect(page).to have_content 'Check-In Receipt'
        expect(page).to have_content current_user.name
        @res.reload
        expect(@res.checkin_handler).to eq(current_user)
        expect(@res.checked_in).not_to be_nil
        if current_user.view_mode == 'admin' ||
           current_user.view_mode == 'superuser'
          visit equipment_item_path(@res.equipment_item)
          expect(page).to have_link('Checked in', href: resource_url(@res))
        end
      end

      it 'does not update equipment items for missing ToS checkbox' do
        @user.update_attributes(terms_of_service_accepted: false)
        visit manage_reservations_for_user_path(@user)
        select "#{@eq_model.equipment_items.first.name}", from: 'Equipment Item'
        click_button 'Check-Out Equipment'

        expect(page).to have_content 'You must confirm that the user accepts '\
          'the Terms of Service.'
        visit equipment_item_path(@res.equipment_model.equipment_items.first)
        expect(page).not_to have_link('Checked out', href: resource_url(@res))
      end

      it 'does not update equipment items for duplicate items' do
        FactoryGirl.create :equipment_item, equipment_model: @eq_model,
                                            name: 'name2'
        @res2 = FactoryGirl.create :valid_reservation,
                                   reserver: @user,
                                   equipment_model: @eq_model
        visit manage_reservations_for_user_path(@user)
        select "#{@eq_model.equipment_items.first.name}",
               from: "reservations_#{@res.id}_equipment_item_id"
        select "#{@eq_model.equipment_items.first.name}",
               from: "reservations_#{@res2.id}_equipment_item_id"
        click_button 'Check-Out Equipment'

        expect(page).to have_content 'The same equipment item cannot be '\
          'simultaneously checked out in multiple reservations.'
        visit equipment_item_path(@res.equipment_model.equipment_items.first)
        expect(page).not_to have_link('Checked out', href: resource_url(@res))
        expect(page).not_to have_link('Checked out', href: resource_url(@res2))
      end
    end

    context 'as guest' do
      it 'should redirect to the catalog page' do
        visit manage_reservations_for_user_path(@user)
        expect(page).to have_content 'Sign In'
        expect(page.current_url).to eq(new_user_session_url)
      end
    end

    context 'as patron' do
      before { sign_in_as_user(@user) }
      after { sign_out }

      it 'should redirect to the catalog page' do
        visit manage_reservations_for_user_path(@user)
        expect(page).to have_content 'Catalog'
        expect(page.current_url).to eq(root_url)
      end
    end

    context 'as checkout person' do
      before { sign_in_as_user(@checkout_person) }
      after { sign_out }

      it_behaves_like 'can handle reservation transactions'
    end

    context 'as admin' do
      before { sign_in_as_user(@admin) }
      after { sign_out }

      it_behaves_like 'can handle reservation transactions'
    end

    context 'as superuser' do
      before { sign_in_as_user(@superuser) }
      after { sign_out }

      it_behaves_like 'can handle reservation transactions'
    end

    context 'ToS checkbox' do
      before(:each) do
        @user.update_attributes(terms_of_service_accepted: false)
      end

      shared_examples 'can utilize the ToS checkbox' do
        before(:each) { visit manage_reservations_for_user_path(@user) }

        it 'fails when the box isn\'t checked off' do
          # skip the checkbox
          select "#{@eq_model.equipment_items.first.name}",
                 from: 'Equipment Item'
          click_button 'Check-Out Equipment'

          expect(page).to have_content 'You must confirm that the user '\
            'accepts the Terms of Service.'
          expect(page.current_url).to \
            eq(manage_reservations_for_user_url(@user))
        end

        it 'succeeds when the box is checked off' do
          check 'terms_of_service_accepted'
          select "#{@eq_model.equipment_items.first.name}",
                 from: 'Equipment Item'
          click_button 'Check-Out Equipment'

          expect(page).to have_content 'Check-Out Receipt'
          expect(page).to have_content current_user.name
          @res.reload
          expect(@res.equipment_item_id).to \
            eq(@eq_model.equipment_items.first.id)
          expect(@res.checkout_handler).to eq(current_user)
          expect(@res.checked_out).not_to be_nil
        end
      end

      context 'as checkout person' do
        before { sign_in_as_user(@checkout_person) }
        after { sign_out }

        it_behaves_like 'can utilize the ToS checkbox'
      end

      context 'as admin' do
        before { sign_in_as_user(@admin) }
        after { sign_out }

        it_behaves_like 'can utilize the ToS checkbox'
      end

      context 'as superuser' do
        before { sign_in_as_user(@superuser) }
        after { sign_out }

        it_behaves_like 'can utilize the ToS checkbox'
      end
    end
  end

  context 'renewing reservations' do
    before(:each) do
      @res =
        FactoryGirl.create :checked_out_reservation, reserver: @user,
                                                     equipment_model: @eq_model
    end

    shared_examples 'can see renew button' do
      before { visit reservation_path(@res) }
      it { expect(page).to have_content 'You are currently eligible to renew' }
    end

    shared_examples 'cannot see renew button' do
      before { visit reservation_path(@res) }
      it do
        expect(page).to have_content 'This item is not currently eligible '\
          'for renewal.'
      end
    end

    shared_examples 'can renew reservation when enabled and available' do
      it do
        AppConfig.first.update_attributes(enable_renewals: true)
        visit reservation_path(@res)
        expect(page).to have_content 'You are currently eligible to renew'
        click_link 'Renew Now', href: renew_reservation_path(@res)
        expect(page).to have_content 'Your reservation has been renewed'
        expect { @res.reload }.to change { @res.due_date }
      end
    end

    shared_examples 'cannot see renew button when disabled' do
      it do
        AppConfig.first.update_attributes(enable_renewals: false)
        visit reservation_path(@res)
        expect(page).not_to have_link 'Renew Now',
                                      href: renew_reservation_path(@res)
      end
    end

    shared_examples 'cannot renew reservation when unavailable' do
      it do
        AppConfig.first.update_attributes(enable_renewals: true)
        FactoryGirl.create :reservation, equipment_model: @eq_model,
                                         start_date: @res.due_date + 1.day,
                                         due_date: @res.due_date + 2.days
        visit reservation_path(@res)
        expect(page).to have_content 'This item is not currently eligible '\
          'for renewal.'
      end
    end

    context 'as patron' do
      before { sign_in_as_user(@user) }
      after { sign_out }

      it_behaves_like 'can renew reservation when enabled and available'
      it_behaves_like 'cannot see renew button when disabled'
      it_behaves_like 'cannot renew reservation when unavailable'
    end

    context 'as checkout person' do
      before { sign_in_as_user(@checkout_person) }
      after { sign_out }

      it_behaves_like 'can renew reservation when enabled and available'
      it_behaves_like 'cannot see renew button when disabled'
      it_behaves_like 'cannot renew reservation when unavailable'
    end

    context 'as admin' do
      before { sign_in_as_user(@admin) }
      after { sign_out }

      it_behaves_like 'can renew reservation when enabled and available'
      it_behaves_like 'cannot see renew button when disabled'
      it_behaves_like 'cannot renew reservation when unavailable'

      context 'respects setting renewal_days_before_due' do
        before do
          @res.equipment_model.update_attributes(renewal_days_before_due: 5)
        end

        context 'before limit' do
          before { @res.update_attributes(due_date: Time.zone.today + 6.days) }

          it_behaves_like 'cannot see renew button'
        end

        context 'after limit' do
          before { @res.update_attributes(due_date: Time.zone.today + 5.days) }

          it_behaves_like 'can see renew button'
        end
      end

      context 'respects setting max_renewal_times' do
        before { @res.equipment_model.update_attributes(max_renewal_times: 3) }

        context 'at limit' do
          before { @res.update_attributes(times_renewed: 3) }

          it_behaves_like 'cannot see renew button'
        end

        context 'below limit' do
          before { @res.update_attributes(times_renewed: 2) }

          it_behaves_like 'can see renew button'
        end
      end

      context 'cannot renew if the reservation is overdue' do
        before { @res.update_attributes(overdue: true) }

        it_behaves_like 'cannot see renew button'
      end
    end

    context 'as superuser' do
      before { sign_in_as_user(@superuser) }
      after { sign_out }

      it_behaves_like 'can renew reservation when enabled and available'
      it_behaves_like 'cannot renew reservation when unavailable'

      it 'can see renew button when disabled' do
        AppConfig.first.update_attributes(enable_renewals: false)
        visit reservation_path(@res)
        expect(page).to have_link 'Renew Now',
                                  href: renew_reservation_path(@res)
      end
    end
  end
end
