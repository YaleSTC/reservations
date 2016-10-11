# frozen_string_literal: true
require 'spec_helper'

describe UserMailer, type: :mailer do
  include EnvHelpers
  def send_email(res_type, override: '', **attrs)
    unless AppConfig.first
      mock_app_config(admin_email: 'admin@email.com',
                      disable_user_emails: false)
    end
    res = FactoryGirl.build_stubbed(res_type, **attrs)
    UserMailer.reservation_status_update(res, override)
  end

  def configure_mailer
    ActionMailer::Base.delivery_method = :test
    ActionMailer::Base.perform_deliveries = true
    ActionMailer::Base.deliveries = []
  end

  shared_examples 'email' do |subject, type, override: '', **attrs|
    it 'sends the appropriate email' do
      mail = send_email(type, override: override, **attrs)
      expect(mail.subject).to include(subject)
    end
    it 'sends an email' do
      mock_app_config(admin_email: 'admin@email.com',
                      disable_user_emails: false)
      configure_mailer
      reserver = FactoryGirl.build_stubbed(:user)
      res = FactoryGirl.build_stubbed(type, reserver: reserver, **attrs)
      expect { UserMailer.reservation_status_update(res, override).deliver_now }
        .to change { ActionMailer::Base.deliveries.count }.by(1)
    end
  end

  describe 'reservation_status_update' do
    it 'sends to the reserver' do
      user = FactoryGirl.build_stubbed(:user)
      allow(User).to receive(:find).with(user.id).and_return(user)
      mail = send_email(:valid_reservation, override: 'requested',
                                            reserver: user)
      expect(mail.to.size).to eq(1)
      expect(mail.to.first).to eq(user.email)
    end
    it 'logs if the env is set' do
      env_wrapper('LOG_EMAILS' => '1') do
        configure_mailer
        expect(Rails.logger).to receive(:info).with(/Sent/).once
        # force a request email; there is not an email for a basic reservation
        send_email(:valid_reservation, override: 'requested').deliver_now
      end
    end

    it "doesn't log if the env is not set" do
      expect(ENV['LOG_EMAILS']).to be_nil
      configure_mailer
      expect(Rails.logger).to receive(:info).with(/Sent/).exactly(0).times
      # force a request email; there is not an email for a basic reservation
      send_email(:valid_reservation, override: 'requested').deliver_now
    end

    it "doesn't send check-out receipts if not checked out" do
      configure_mailer
      mail = send_email(:valid_reservation, override: 'checked out').deliver_now
      expect(mail).to be_nil
    end

    it "doesn't send fine emails when there is no late fee" do
      configure_mailer
      mock_app_config(admin_email: 'admin@email.com',
                      disable_user_emails: false)
      res = FactoryGirl.build_stubbed(:overdue_returned_reservation)
      allow(res.equipment_model).to receive(:late_fee).and_return(0)
      mail = UserMailer.reservation_status_update(res).deliver_now
      expect(mail).to be_nil
    end

    it "doesn't send at all if disable_user_emails is set" do
      configure_mailer
      mock_app_config(admin_email: 'admin@email.com', disable_user_emails: true)
      mail = send_email(:valid_reservation).deliver_now
      expect(mail).to be_nil
    end

    it_behaves_like 'email', 'Denied', :request, status: 'denied'
    it_behaves_like 'email', 'Missed', :missed_reservation
    it_behaves_like 'email', 'Checked Out', :checked_out_reservation
    it_behaves_like 'email', 'Overdue', :overdue_reservation
    it_behaves_like 'email', 'Returned', :checked_in_reservation
    it_behaves_like 'email', 'Returned Overdue', :overdue_returned_reservation

    it_behaves_like 'email', 'Request Approved', :valid_reservation,
                    start_date: Time.zone.today + 1.day,
                    due_date: Time.zone.today + 2.days,
                    flags: Reservation::FLAGS[:request]
    it_behaves_like 'email', 'Request Approved', :valid_reservation,
                    override: 'request approved',
                    flags: Reservation::FLAGS[:request]
    it_behaves_like 'email', 'Request Expired', :request,
                    status: 'denied', flags: (Reservation::FLAGS[:request] |
                                              Reservation::FLAGS[:expired])

    it_behaves_like 'email', 'Starts Today', :upcoming_reservation
    it_behaves_like 'email', 'Due Today', :checked_out_reservation,
                    due_date: Time.zone.today

    it_behaves_like 'email', 'Checked Out', :checked_out_reservation,
                    override: 'checked out', due_date: Time.zone.today
    it_behaves_like 'email', 'Checked Out', :overdue_reservation,
                    override: 'checked out'
  end
end
