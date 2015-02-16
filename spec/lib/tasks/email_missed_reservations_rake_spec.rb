require 'spec_helper'

# see http://robots.thoughtbot.com/test-rake-tasks-like-a-boss
describe 'email_missed_reservations' do
  include_context 'rake'

  before(:all) { FactoryGirl.create(:app_config) }

  before(:each) do
    @missed = FactoryGirl.create(:missed_reservation,
                                 start_date: Date.current - 2.days,
                                 due_date: Date.current - 1.days)
    @not_missed = FactoryGirl.create(:valid_reservation)
  end

  it 'sends emails for approved reservations that were missed' do
    @missed.update_attributes(approval_status: 'approved')
    expect { subject.invoke }.to(
      change { ActionMailer::Base.deliveries.count }.by(1))
  end

  it 'updates approval_status after email is sent' do
    @missed.update_attributes(approval_status: 'approved')
    expect { subject.invoke }.to(
      change { Reservation.find(@missed.id).approval_status }.from(
        'approved').to('missed_and_emailed'))
  end

  it 'sends emails for auto reservations that were missed' do
    @missed.update_attributes(approval_status: 'auto')
    expect { subject.invoke }.to(
      change { ActionMailer::Base.deliveries.count }.by(1))
  end

  it "doesn't send emails for missed not approved or auto reservations" do
    @missed.update_attributes(approval_status: 'asdfj')
    expect { subject.invoke }.to_not(
      change { ActionMailer::Base.deliveries.count })
  end
end
