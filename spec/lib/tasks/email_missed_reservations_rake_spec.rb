require 'spec_helper'

# see http://robots.thoughtbot.com/test-rake-tasks-like-a-boss
describe 'email_missed_reservations' do
  include_context 'rake'

  before(:each) do
    mock_app_config(admin_email: 'admin@email.com', disable_user_emails: false,
                    send_notifications_for_deleted_missed_reservations: true)
    @missed = FactoryGirl.create(:missed_reservation,
                                 start_date: Time.zone.today - 2.days,
                                 due_date: Time.zone.today - 1.day)
    @not_missed = FactoryGirl.create(:valid_reservation)
  end

  it 'updates flags after email is sent' do
    expect { subject.invoke }.to \
      change { Reservation.find(@missed.id).flagged?(:missed_email_sent) }
      .from(false).to(true)
  end

  it 'sends emails for reservations that were missed' do
    expect(@missed.missed?).to be_truthy
    expect { subject.invoke }.to \
      change { ActionMailer::Base.deliveries.count }.by(1)
  end

  it "doesn't send emails if the missed_email_sent flag is set" do
    @missed.flag(:missed_email_sent)
    @missed.save!
    expect { subject.invoke }.not_to \
      change { ActionMailer::Base.deliveries.count }
  end
end
