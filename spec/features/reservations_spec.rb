# frozen_string_literal: true
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
        expect(page).to have_content 'Confirm Reservation'
        click_button 'Finalize Reservation'

        # check that reservation was created with correct dates
        query =
          Reservation.for_eq_model(@eq_model.id).for_reserver(reserver.id)
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
        expect(page).to have_content 'Confirm Reservation Request'
        find(:xpath, "//textarea[@id='reservation_notes']").set 'Because'
        click_button 'Submit Request'

        # check that reservation request was created with correct dates
        query =
          Reservation.for_eq_model(@eq_model.id).for_reserver(reserver.id)
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
        expect(page).to have_content 'Confirm Reservation'
        expect(page).to have_content 'Please be aware of the following errors:'
        find(:xpath, "//textarea[@id='reservation_notes']").set 'Because'
        click_button 'Finalize Reservation'

        # check that reservation was created with correct dates
        query =
          Reservation.for_eq_model(@eq_model.id).for_reserver(reserver.id)
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
        before do
          allow(@app_config).to receive(:override_on_create).and_return(false)
        end

        it_behaves_like 'can create valid reservation', @user
        it_behaves_like 'can create reservation request', @user
      end

      context 'with override permissions' do
        before do
          allow(@app_config).to receive(:override_on_create).and_return(true)
        end

        it_behaves_like 'can create failing reservation', @user
      end
    end

    context 'by admins' do
      before { sign_in_as_user(@admin) }
      after { sign_out }

      context 'with override disabled' do
        before do
          allow(@app_config).to receive(:override_on_create).and_return(false)
        end

        it_behaves_like 'can create valid reservation', @user
        it_behaves_like 'can create failing reservation', @user
      end

      context 'with override enabled' do
        before do
          allow(@app_config).to receive(:override_on_create).and_return(true)
        end

        it_behaves_like 'can create failing reservation', @user
      end
    end

    context 'by superusers' do
      before { sign_in_as_user(@superuser) }
      after { sign_out }

      context 'with override disabled' do
        before do
          allow(@app_config).to receive(:override_on_create).and_return(false)
        end

        it_behaves_like 'can create valid reservation', @user
        it_behaves_like 'can create failing reservation', @user
      end

      context 'with override enabled' do
        before do
          allow(@app_config).to receive(:override_on_create).and_return(true)
        end

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
        check @checked_out_res.equipment_item.name.to_s
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
        select @eq_model.equipment_items.first.name.to_s, from: 'Equipment Item'
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
        select @eq_model.equipment_items.first.name.to_s, from: 'Equipment Item'
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
        check @res.equipment_item.name.to_s
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
        select @eq_model.equipment_items.first.name.to_s, from: 'Equipment Item'
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
        select @eq_model.equipment_items.first.name.to_s,
               from: "reservations_#{@res.id}_equipment_item_id"
        select @eq_model.equipment_items.first.name.to_s,
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
          select @eq_model.equipment_items.first.name.to_s,
                 from: 'Equipment Item'
          click_button 'Check-Out Equipment'

          expect(page).to have_content 'You must confirm that the user '\
            'accepts the Terms of Service.'
          expect(page.current_url).to \
            eq(manage_reservations_for_user_url(@user))
        end

        it 'succeeds when the box is checked off' do
          check 'terms_of_service_accepted'
          select @eq_model.equipment_items.first.name.to_s,
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
        allow(@app_config).to receive(:enable_renewals).and_return(true)
        visit reservation_path(@res)
        expect(page).to have_content 'You are currently eligible to renew'
        click_link 'Renew Now', href: renew_reservation_path(@res)
        expect(page).to have_content 'Your reservation has been renewed'
        expect { @res.reload }.to change { @res.due_date }
      end
    end

    shared_examples 'cannot see renew button when disabled' do
      it do
        allow(@app_config).to receive(:enable_renewals).and_return(false)
        visit reservation_path(@res)
        expect(page).not_to have_link 'Renew Now',
                                      href: renew_reservation_path(@res)
      end
    end

    shared_examples 'cannot renew reservation when unavailable' do
      it do
        allow(@app_config).to receive(:enable_renewals).and_return(true)
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
        before { @res.update_columns(overdue: true) }

        it_behaves_like 'cannot see renew button'
      end
    end

    context 'as superuser' do
      before { sign_in_as_user(@superuser) }
      after { sign_out }

      it_behaves_like 'can renew reservation when enabled and available'
      it_behaves_like 'cannot renew reservation when unavailable'

      it 'can see renew button when disabled' do
        allow(@app_config).to receive(:enable_renewals).and_return(false)
        visit reservation_path(@res)
        expect(page).to have_link 'Renew Now',
                                  href: renew_reservation_path(@res)
      end
    end
  end

  context 'valid items on confirmation page' do
    before(:each) do
      empty_cart
      add_item_to_cart(@eq_model)
      update_cart_start_date(Time.zone.today)
      due_date = Time.zone.today + 1.day
      update_cart_due_date(due_date)
    end

    shared_examples 'can make valid change to reservation' do |reserver|
      before(:each) do
        visit new_reservation_path
      end
      let(:reserver) { reserver }
      str = reserver ? 'for other user successfully' : 'successfully'
      it str do
        quantity_forms = page.all('#quantity_form')
        avail_quantity = @eq_model.num_available(Time.zone.today,
                                                 Time.zone.today + 1.day)
        fill_in "quantity_field_#{@eq_model.id}", # edit and submit
                with: avail_quantity

        quantity_forms[0].submit_form!
        # loading right page
        expect(page).to have_content 'Confirm Reservation'
        expect(page).not_to have_content 'Confirm Reservation Request'
        # changes applied
        expect(page).to have_selector("input[value='#{avail_quantity}']")
      end
    end

    shared_examples 'will load request page if item is invalid' do |reserver|
      before(:each) do
        allow(@app_config).to receive(:override_on_create).and_return(false)
        visit new_reservation_path
      end
      let(:reserver) { reserver }
      str = reserver ? 'for other user successfully' : 'successfully'
      it str do
        # change cart to have invalid properties, and check if it loads request
        quantity_forms = page.all('#quantity_form')
        fill_in "quantity_field_#{@eq_model.id}",
                with: (@eq_model.max_per_user + 1)
        quantity_forms[0].submit_form!
        # loading right page
        expect(page).to have_content 'Confirm Reservation Request'
        expect(page).to have_content AppConfig.get(:request_text)
        # changes applied
        expect(page).to \
          have_selector("input[value='#{@eq_model.max_per_user + 1}']")
      end
    end

    shared_examples 'can remove a valid item' do |reserver|
      before(:each) do
        @eq_model2 = FactoryGirl.create(:equipment_model, category: @category)
        FactoryGirl.create(:equipment_item, equipment_model: @eq_model2)
        add_item_to_cart(@eq_model2)
        visit new_reservation_path
      end
      let(:reserver) { reserver }
      str = reserver ? 'for other user successfully' : 'successfully'
      it str do
        # removing a valid item
        quantity_forms = page.all('#quantity_form')
        fill_in "quantity_field_#{@eq_model.id}",
                with: 0
        quantity_forms[0].submit_form!
        # changes applied
        expect(page).not_to have_content @eq_model.name
      end
    end

    shared_examples 'can remove all items' do |reserver|
      before(:each) do
        @eq_model2 = FactoryGirl.create(:equipment_model, category: @category)
        FactoryGirl.create(:equipment_item, equipment_model: @eq_model2)
        add_item_to_cart(@eq_model2)
        visit new_reservation_path
      end
      let(:reserver) { reserver }
      str = reserver ? 'for other user successfully' : 'successfully'
      it str do
        # removing all items
        quantity_forms = page.all('#quantity_form')
        fill_in "quantity_field_#{@eq_model.id}",
                with: 0
        quantity_forms[0].submit_form!
        quantity_forms = page.all('#quantity_form') # gets an updated page
        fill_in "quantity_field_#{@eq_model2.id}",
                with: 0
        quantity_forms[0].submit_form!
        # redirects to catalog (implies that cart is empty)
        expect(page).to have_content 'Catalog'
        expect(page).not_to have_content 'Confirm Reservation'
      end
    end

    shared_examples 'can make valid date change' do |reserver|
      before(:each) do
        visit new_reservation_path
      end
      let(:reserver) { reserver }
      str = reserver ? 'for other user successfully' : 'successfully'
      it str do
        # valid change
        due_date = Time.zone.today + 2.days
        fill_in 'cart_due_date_cart', with: due_date
        find(:xpath, "//input[@id='date_end_alt']", visible: :all).set due_date
        find('#dates_form').submit_form!
        # loads right page
        expect(page).to have_content 'Confirm Reservation'
        expect(page).not_to have_content 'Confirm Reservation Request'
        # has correct date
        expect(page).to have_selector("input[value='#{due_date}']",
                                      visible: :all)
      end
    end

    shared_examples 'will load request if invalid date change' do |reserver|
      before(:each) do
        allow(@app_config).to receive(:override_on_create).and_return(false)
        visit new_reservation_path
      end
      let(:reserver) { reserver }
      str = reserver ? 'for other user successfully' : 'successfully'

      it str do
        # change to invalid date
        bad_due_date =
          Time.zone.today + (@eq_model.maximum_checkout_length + 1).days
        fill_in 'cart_due_date_cart', with: bad_due_date
        find(:xpath, "//input[@id='date_end_alt']", visible: :all)
          .set bad_due_date
        find('#dates_form').submit_form!
        # loads right page
        expect(page).to have_content 'Confirm Reservation Request'
        expect(page).to have_content AppConfig.get(:request_text)
        # has altered date
        expect(page).to have_selector("input[value='#{bad_due_date}']",
                                      visible: :all)
      end
    end

    shared_examples 'can change back to valid dates after invalid' do |reserver|
      before(:each) do
        visit new_reservation_path
      end
      let(:reserver) { reserver }
      str = reserver ? 'for other user successfully' : 'successfully'

      it str do
        # change to invalid date
        bad_due_date =
          Time.zone.today + (@eq_model.maximum_checkout_length + 1).days
        fill_in 'cart_due_date_cart', with: bad_due_date
        find(:xpath, "//input[@id='date_end_alt']", visible: :all)
          .set bad_due_date
        find('#dates_form').submit_form!
        # changes back to valid date
        due_date = Time.zone.today + 1.day
        fill_in 'cart_due_date_cart', with: due_date
        find(:xpath, "//input[@id='date_end_alt']", visible: :all).set due_date
        find('#dates_form').submit_form!
        # redirect to right page
        expect(page).to have_content 'Confirm Reservation'
        expect(page).not_to have_content 'Confirm Reservation Request'
        # has correct dates
        expect(page).to have_selector("input[value='#{due_date}']",
                                      visible: :all)
      end
    end

    context 'as patron' do
      before { sign_in_as_user(@user) }
      after { sign_out }

      it_behaves_like 'can make valid change to reservation'
      it_behaves_like 'will load request page if item is invalid'
      it_behaves_like 'can remove a valid item'
      it_behaves_like 'can remove all items'
      it_behaves_like 'can make valid date change'
      it_behaves_like 'will load request if invalid date change'
      it_behaves_like 'can change back to valid dates after invalid'
    end

    context 'as checkout person' do
      before { sign_in_as_user(@checkout_person) }
      after { sign_out }

      it_behaves_like 'can make valid change to reservation'
      it_behaves_like 'will load request page if item is invalid'
      it_behaves_like 'can remove a valid item'
      it_behaves_like 'can remove all items'
      it_behaves_like 'can make valid date change'
      it_behaves_like 'will load request if invalid date change'
      it_behaves_like 'can change back to valid dates after invalid'
    end
  end

  context 'invalid items on confirm page' do
    before(:each) do
      empty_cart
      @eq_model2 = FactoryGirl.create(:equipment_model, category: @category)
      FactoryGirl.create(:equipment_item, equipment_model: @eq_model2)
      add_item_to_cart(@eq_model)
      add_item_to_cart(@eq_model2)
      quantity_forms = page.all('#quantity_form')
      fill_in "quantity_field_#{@eq_model.id}",
              with: (@eq_model.max_per_user + 1)
      quantity_forms[0].submit_form!
      update_cart_start_date(Time.zone.today)
      due_date = Time.zone.today + 1.day
      update_cart_due_date(due_date)
      visit new_reservation_path
    end

    shared_examples 'loads reservation page if item is now valid' do |reserver|
      let(:reserver) { reserver }
      str = reserver ? 'for other user successfully' : 'successfully'
      it str do
        # change cart to have invalid properties, and check if it loads request
        quantity_forms = page.all('#quantity_form')
        fill_in "quantity_field_#{@eq_model.id}",
                with: @eq_model.max_per_user
        quantity_forms[0].submit_form!
        expect(page).to have_content 'Confirm Reservation'
      end
    end

    shared_examples 'can remove an invalid item' do |reserver|
      let(:reserver) { reserver }
      str = reserver ? 'for other user successfully' : 'successfully'
      it str do
        # removing a valid item
        quantity_forms = page.all('#quantity_form')
        fill_in "quantity_field_#{@eq_model.id}",
                with: 0
        quantity_forms[0].submit_form!
        expect(page).not_to have_content @eq_model.name
      end
    end

    context 'as patron' do
      before { sign_in_as_user(@user) }
      after { sign_out }

      it_behaves_like 'loads reservation page if item is now valid'
      it_behaves_like 'can remove an invalid item'
    end

    context 'as checkout person' do
      before { sign_in_as_user(@checkout_person) }
      after { sign_out }

      it_behaves_like 'loads reservation page if item is now valid'
      it_behaves_like 'can remove an invalid item'
    end
  end
  context 'accessing /reservation/new path with empty cart' do
    before(:each) do
      sign_in_as_user(@admin)
      empty_cart
      visit equipment_model_path(@eq_model)
    end
    after(:each) { sign_out }
    it 'handles direct url' do
      visit new_reservation_path
      expect(page.current_url).to include(root_path)
      expect(page).to have_content('Catalog')
    end
    it 'handles pressing reserve button' do
      click_link('Reserve')
      expect(page.current_url).to include(equipment_models_path)
      expect(page).to have_content('Description')
    end
  end
end
