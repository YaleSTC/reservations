# frozen_string_literal: true
require 'spec_helper'

describe ManageController, type: :controller do
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
  describe '#show (GET /manage/:user_id)' do
    # Access: admins and checkout persons
    # Functionality:
    # - assigns @user, @check_out_set and @check_in_set
    # - renders :show

    shared_examples 'can access #show' do
      let!(:user) { UserMock.new(traits: [:findable]) }
      before(:each) do
        allow(user).to receive(:due_for_checkout)
          .and_return(instance_spy('ActiveRecord::Relation'))
        allow(user).to receive(:due_for_checkin)
          .and_return(instance_spy('ActiveRecord::Relation'))
        get :show, user_id: user.id
      end
      it { expect(response).to be_success }
      it { is_expected.to render_template(:show) }
      it 'assigns @user correctly' do
        expect(assigns(:user)).to eq(user)
      end
      it 'assigns @check_out_set correctly' do
        expect(assigns(:check_out_set)).to eq(user.due_for_checkout)
      end
      it 'assigns @check_in_set correctly' do
        expect(assigns(:check_in_set)).to eq(user.due_for_checkin)
      end
    end

    context 'when accessed by admin' do
      before(:each) { mock_user_sign_in(UserMock.new(:admin)) }
      include_examples 'can access #show'
    end

    context 'when accessed by checkout person' do
      before(:each) { mock_user_sign_in(UserMock.new(:checkout_person)) }
      include_examples 'can access #show'
    end
    context 'when accessed by patron' do
      before(:each) do
        user = UserMock.new
        mock_user_sign_in(user)
        get :show, user_id: user.id
      end
      include_examples 'redirected request'
    end
  end
  describe '#checkout (PUT /manage/checkout/:user_id)' do
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
    # - sets reservation status to 'checked_out'

    # Note: Many of these can be cross-applied to #checkin as well

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

    shared_examples 'has successful checkout' do
      before(:each) do
        @item =
          FactoryGirl.create(:equipment_item,
                             equipment_model: @reservation.equipment_model)
        reservations_params =
          { @reservation.id.to_s => { notes: '',
                                      equipment_item_id: @item.id } }
        ActionMailer::Base.deliveries = []
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
        expect(@reservation.reserved?).to be_truthy
        @reservation.reload
        expect(@reservation.checkout_handler).to be_a(User)
        expect(@reservation.checked_out).to_not be_nil
        expect(@reservation.equipment_item).to eq @item
        expect(@reservation.checked_out).to be_truthy
      end

      it 'updates the equipment item history' do
        expect { @item.reload }.to change(@item, :notes)
      end

      it 'updates the reservation notes' do
        expect { @reservation.reload }.to change(@reservation, :notes)
      end

      it 'sends checkout receipts' do
        expect(ActionMailer::Base.deliveries.count).to eq(1)
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

      include_examples 'redirected request'
    end

    it_behaves_like 'inaccessible by banned user' do
      before { put :checkout, user_id: @banned.id }
    end

    context 'when tos not accepted and not checked off' do
      before do
        request.env['HTTP_REFERER'] = 'where_i_came_from'
        sign_in @admin
        @user.update_attributes(terms_of_service_accepted: false)
        put :checkout, user_id: @user.id, reservations: {}
      end
      it { expect(response).to redirect_to 'where_i_came_from' }
    end

    context 'when tos accepted' do
      before do
        sign_in @admin
        @user.update_attributes(terms_of_service_accepted: false)
        @item =
          FactoryGirl.create(:equipment_item,
                             equipment_model: @reservation.equipment_model)
        reservations_params =
          { @reservation.id.to_s => { notes: '',
                                      equipment_item_id: @item.id } }
        put :checkout, user_id: @user.id, reservations: reservations_params,
                       terms_of_service_accepted: true
      end

      it { expect(response).to be_success }
    end

    context 'with duplicate equipment item selection' do
      before do
        request.env['HTTP_REFERER'] = 'where_i_came_from'
        sign_in @admin
        @item =
          FactoryGirl.create :equipment_item,
                             equipment_model: @reservation.equipment_model
        FactoryGirl.create :equipment_item,
                           equipment_model: @reservation.equipment_model
        @res2 =
          FactoryGirl.create :valid_reservation,
                             reserver: @user,
                             equipment_model: @reservation.equipment_model
        res_params = { notes: '', equipment_item_id: @item.id }
        reservations_params = { @reservation.id.to_s => res_params,
                                @res2.id.to_s => res_params }
        put :checkout, user_id: @user.id, reservations: reservations_params
      end

      it { expect(response).to redirect_to 'where_i_came_from' }

      it 'does not update the equipment item history' do
        expect { @item.reload }.not_to change(@item, :notes)
      end
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

  describe '#checkin (PUT /manage/check-in/:user_id)' do
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

      include_examples 'redirected request'
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
        put :checkin, user_id: @user.id, reservations: {}
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

  describe '#send_receipt (PUT /manage/send_receipt/:receipt_id)' do
    before { mock_user_sign_in(UserMock.new(:checkout_person)) }
    let!(:res) do
      FactoryGirl.build_stubbed(:valid_reservation).tap do |r|
        allow(Reservation).to receive(:find).with(r.id.to_s).and_return(r)
      end
    end

    context 'successfully emails' do
      before do
        allow(UserMailer).to \
          receive_message_chain(:reservation_status_update, :deliver_now)
          .and_return(true)
        put :send_receipt, receipt_id: res.id
      end
      it { is_expected.to redirect_to(res) }
      it { is_expected.to set_flash[:notice] }
    end

    context 'fails to send email' do
      before do
        allow(UserMailer).to \
          receive_message_chain(:reservation_status_update, :deliver_now)
          .and_return(false)
        put :send_receipt, receipt_id: res.id
      end
      it { is_expected.to redirect_to(res) }
      it { is_expected.to set_flash[:error] }
    end
  end
end
