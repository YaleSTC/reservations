require 'spec_helper'

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
  before(:all) do
    @app_config = FactoryGirl.create(:app_config)
  end
  before(:each) do
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
      @mail = UserMailer.reservation_status_update(@res).deliver
      expect(@mail.to.size).to eq(1)
      expect(@mail.to.first).to eq(reserver.email)
    end

    it 'sends an email' do
      @mail = UserMailer.reservation_status_update(@res).deliver
      expect(ActionMailer::Base.deliveries.count).to eq(1)
    end

    it 'sends denied notifications' do
      @res.update_attributes(status: 'denied')
      expect(@res.denied?).to be_truthy
      @mail = UserMailer.reservation_status_update(@res).deliver
      expect(@mail.subject).to eq(
        "[Reservations] #{@res.equipment_model.name} Denied")
    end

    it 'sends approved request notifications' do
      @res.update_attributes(status: 'reserved',
                             flags: Reservation::FLAGS[:request])
      @mail = UserMailer.reservation_status_update(@res).deliver
      expect(@mail.subject).to eq(
        "[Reservations] #{@res.equipment_model.name} Request Approved")
    end

    it 'sends approved request notifications for requests starting today' do
      @res.update_attributes(status: 'reserved',
                             flags: Reservation::FLAGS[:request],
                             start_date: Time.zone.today,
                             due_date: Time.zone.today + 1)
      @mail = UserMailer.reservation_status_update(@res,
                                                   'request approved').deliver
      expect(@mail.subject).to eq(
        "[Reservations] #{@res.equipment_model.name} Request Approved")
    end

    it 'sends reminders to check-out' do
      @res.update_attributes(
        FactoryGirl.attributes_for(:upcoming_reservation))
      @mail = UserMailer.reservation_status_update(@res).deliver
      expect(@mail.subject).to eq(
        "[Reservations] #{@res.equipment_model.name} Starts Today")
    end

    it 'sends missed notifications' do
      @res.update_attributes(FactoryGirl.attributes_for(:missed_reservation))
      @mail = UserMailer.reservation_status_update(@res).deliver
      expect(@mail.subject).to eq(
        "[Reservations] #{@res.equipment_model.name} Missed")
    end

    it 'sends check-out receipts' do
      @res.update_attributes(
        FactoryGirl.attributes_for(:checked_out_reservation))
      @mail = UserMailer.reservation_status_update(@res).deliver
      expect(@mail.subject).to eq(
        "[Reservations] #{@res.equipment_model.name} Checked Out")
    end

    it "doesn't sends check-out receipts if not checked out" do
      @res.update_attributes(
        FactoryGirl.attributes_for(:valid_reservation))
      expect(@res.checked_out).to be_nil
      @mail = UserMailer.reservation_status_update(@res, 'checked out').deliver
      expect(@mail).to be_nil
    end

    it 'sends check-out receipts for reservations due today' do
      @res.update_attributes(
        FactoryGirl.attributes_for(:checked_out_reservation,
                                   due_date: Time.zone.today))
      @mail = UserMailer.reservation_status_update(@res, 'checked out').deliver
      expect(@mail.subject).to eq(
        "[Reservations] #{@res.equipment_model.name} Checked Out")
    end

    it 'sends check-out receipts for overdue reservations' do
      @res.update_attributes(FactoryGirl.attributes_for(:overdue_reservation))
      @mail = UserMailer.reservation_status_update(@res, 'checked out').deliver
      expect(@mail.subject).to eq(
        "[Reservations] #{@res.equipment_model.name} Checked Out")
    end

    it 'sends reminders to check-in' do
      @res.update_attributes(
        FactoryGirl.attributes_for(:checked_out_reservation,
                                   due_date: Time.zone.today))
      @mail = UserMailer.reservation_status_update(@res).deliver
      expect(@mail.subject).to eq(
        "[Reservations] #{@res.equipment_model.name} Due Today")
    end

    it 'sends check-in receipts' do
      @res.update_attributes(
        FactoryGirl.attributes_for(:checked_in_reservation))
      @mail = UserMailer.reservation_status_update(@res).deliver
      expect(@mail.subject).to eq(
        "[Reservations] #{@res.equipment_model.name} Returned")
    end

    it 'sends overdue equipment reminders' do
      @res.update_attributes(FactoryGirl.attributes_for(:overdue_reservation))
      @mail = UserMailer.reservation_status_update(@res).deliver
      expect(@mail.subject).to eq(
        "[Reservations] #{@res.equipment_model.name} Overdue")
    end

    it 'sends fine emails for overdue equipment' do
      @res.update_attributes(FactoryGirl.attributes_for(:checked_in_reservation,
                                                        :overdue))
      @mail = UserMailer.reservation_status_update(@res).deliver
      expect(@mail.subject).to eq(
        "[Reservations] #{@res.equipment_model.name} Returned Overdue")
    end

    it "doesn't send fine emails when there is no late fee" do
      @res.update_attributes(FactoryGirl.attributes_for(:checked_in_reservation,
                                                        :overdue))
      @res.equipment_model.update_attributes(late_fee: 0)
      @mail = UserMailer.reservation_status_update(@res).deliver
      expect(@mail).to be_nil
    end

    it "doesn't send at all if disable_user_emails is set" do
      AppConfig.first.update_attributes(disable_user_emails: true)
      @mail = UserMailer.reservation_status_update(@res).deliver
      expect(@mail).to be_nil
    end
  end
end
