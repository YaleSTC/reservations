# frozen_string_literal: true
require 'spec_helper'
include EnvHelpers

shared_examples_for 'valid user email' do
  it 'sends to the reserver' do
    expect(@mail.to.size).to eq(1)
    expect(@mail.to.first).to eq(reserver.email)
  end
  it 'sends an email' do
    expect(ActionMailer::Base.deliveries.count).to eq(1)
  end
  # FIXME: Workaround for #398 disables this functionality for RSpec testing
  # it "is from the admin" do
  #   expect(@mail.from.size).to eq(1)
  #   expect(@mail.from.first).to eq(AppConfig.first.admin_email)
  # end
end

shared_examples_for 'contains reservation' do
  it 'has reservation link' do
    # body contains link to the reservation
    expect(@mail.body).to \
      include("<a href=\"http://0.0.0.0:3000/reservations/#{@res.id}\"")
  end
end

describe UserMailer, type: :mailer do
  before(:each) do
    @ac = mock_app_config(admin_email: 'admin@email.com',
                          disable_user_emails: false)
    ActionMailer::Base.delivery_method = :test
    ActionMailer::Base.perform_deliveries = true
    ActionMailer::Base.deliveries = []
    @res = FactoryGirl.create(:valid_reservation,
                              reserver: reserver,
                              start_date: Time.zone.today + 1)
  end
  let!(:reserver) { FactoryGirl.create(:user) }

  describe 'reservation_status_update' do
    it 'sends to the reserver' do
      # force a request email; there is not an email for a basic reservation
      @mail = UserMailer.reservation_status_update(@res,
                                                   'requested').deliver_now
      expect(@mail.to.size).to eq(1)
      expect(@mail.to.first).to eq(reserver.email)
    end

    it 'sends an email' do
      # force a request email; there is not an email for a basic reservation
      @mail = UserMailer.reservation_status_update(@res,
                                                   'requested').deliver_now
      expect(ActionMailer::Base.deliveries.count).to eq(1)
    end

    it 'logs if the env is set' do
      env_wrapper('LOG_EMAILS' => '1') do
        expect(Rails.logger).to receive(:info).with(/Sent/).once
        # force a request email; there is not an email for a basic reservation
        @mail = UserMailer.reservation_status_update(@res,
                                                     'requested').deliver_now
      end
    end

    it "doesn't log if the env is not set" do
      expect(ENV['LOG_EMAILS']).to be_nil
      expect(Rails.logger).to receive(:info).with(/Sent/).exactly(0).times
      # force a request email; there is not an email for a basic reservation
      @mail = UserMailer.reservation_status_update(@res,
                                                   'requested').deliver_now
    end

    it 'sends denied notifications' do
      @res.update_attributes(status: 'denied')
      expect(@res.denied?).to be_truthy
      @mail = UserMailer.reservation_status_update(@res).deliver_now
      expect(@mail.subject).to \
        eq("[Reservations] #{@res.equipment_model.name} Denied")
    end

    it 'sends approved request notifications' do
      @res.update_attributes(status: 'reserved',
                             flags: Reservation::FLAGS[:request])
      @mail = UserMailer.reservation_status_update(@res).deliver_now
      expect(@mail.subject).to \
        eq("[Reservations] #{@res.equipment_model.name} Request Approved")
    end

    it 'sends approved request notifications for requests starting today' do
      @res.update_attributes(status: 'reserved',
                             flags: Reservation::FLAGS[:request],
                             start_date: Time.zone.today,
                             due_date: Time.zone.today + 1)
      @mail =
        UserMailer.reservation_status_update(@res,
                                             'request approved').deliver_now
      expect(@mail.subject).to \
        eq("[Reservations] #{@res.equipment_model.name} Request Approved")
    end

    it 'sends expired request notifications' do
      @res.update_attributes(status: 'denied',
                             flags: (Reservation::FLAGS[:request] |
                                     Reservation::FLAGS[:expired]))
      @mail = UserMailer.reservation_status_update(@res).deliver_now
      expect(@mail.subject).to \
        eq("[Reservations] #{@res.equipment_model.name} Request Expired")
    end

    it 'sends reminders to check-out' do
      @res.update_attributes(FactoryGirl.attributes_for(:upcoming_reservation))
      @mail = UserMailer.reservation_status_update(@res).deliver_now
      expect(@mail.subject).to \
        eq("[Reservations] #{@res.equipment_model.name} Starts Today")
    end

    it 'sends missed notifications' do
      @res.update_attributes(FactoryGirl.attributes_for(:missed_reservation))
      @mail = UserMailer.reservation_status_update(@res).deliver_now
      expect(@mail.subject).to \
        eq("[Reservations] #{@res.equipment_model.name} Missed")
    end

    it 'sends check-out receipts' do
      @res.update_attributes(
        FactoryGirl.attributes_for(:checked_out_reservation)
      )
      @mail = UserMailer.reservation_status_update(@res).deliver_now
      expect(@mail.subject).to \
        eq("[Reservations] #{@res.equipment_model.name} Checked Out")
    end

    it "doesn't sends check-out receipts if not checked out" do
      @res.update_attributes(FactoryGirl.attributes_for(:valid_reservation))
      expect(@res.checked_out).to be_nil
      @mail =
        UserMailer.reservation_status_update(@res, 'checked out').deliver_now
      expect(@mail).to be_nil
    end

    it 'sends check-out receipts for reservations due today' do
      @res.update_attributes(
        FactoryGirl.attributes_for(:checked_out_reservation,
                                   due_date: Time.zone.today)
      )
      @mail =
        UserMailer.reservation_status_update(@res, 'checked out').deliver_now
      expect(@mail.subject).to \
        eq("[Reservations] #{@res.equipment_model.name} Checked Out")
    end

    it 'sends check-out receipts for overdue reservations' do
      @res.update_attributes(FactoryGirl.attributes_for(:overdue_reservation))
      @mail =
        UserMailer.reservation_status_update(@res, 'checked out').deliver_now
      expect(@mail.subject).to \
        eq("[Reservations] #{@res.equipment_model.name} Checked Out")
    end

    it 'sends reminders to check-in' do
      @res.update_attributes(
        FactoryGirl.attributes_for(:checked_out_reservation,
                                   due_date: Time.zone.today)
      )
      @mail = UserMailer.reservation_status_update(@res).deliver_now
      expect(@mail.subject).to \
        eq("[Reservations] #{@res.equipment_model.name} Due Today")
    end

    it 'sends check-in receipts' do
      @res.update_attributes(
        FactoryGirl.attributes_for(:checked_in_reservation)
      )
      @mail = UserMailer.reservation_status_update(@res).deliver_now
      expect(@mail.subject).to \
        eq("[Reservations] #{@res.equipment_model.name} Returned")
    end

    it 'sends overdue equipment reminders' do
      @res.update_attributes(FactoryGirl.attributes_for(:overdue_reservation))
      @mail = UserMailer.reservation_status_update(@res).deliver_now
      expect(@mail.subject).to \
        eq("[Reservations] #{@res.equipment_model.name} Overdue")
    end

    it 'sends fine emails for overdue equipment' do
      @res.update_attributes(FactoryGirl.attributes_for(:checked_in_reservation,
                                                        :overdue))
      @mail = UserMailer.reservation_status_update(@res).deliver_now
      expect(@mail.subject).to \
        eq("[Reservations] #{@res.equipment_model.name} Returned Overdue")
    end

    it "doesn't send fine emails when there is no late fee" do
      @res.update_attributes(FactoryGirl.attributes_for(:checked_in_reservation,
                                                        :overdue))
      @res.equipment_model.update_attributes(late_fee: 0)
      @mail = UserMailer.reservation_status_update(@res).deliver_now
      expect(@mail).to be_nil
    end

    it "doesn't send at all if disable_user_emails is set" do
      allow(@ac).to receive(:disable_user_emails).and_return(true)
      @mail = UserMailer.reservation_status_update(@res).deliver_now
      expect(@mail).to be_nil
    end
  end
end
