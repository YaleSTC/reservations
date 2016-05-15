require 'spec_helper'

# see http://robots.thoughtbot.com/test-rake-tasks-like-a-boss
describe 'email_checkout_reminder' do
  include_context 'rake'

  before(:each) do
    @ac = mock_app_config(admin_email: 'admin@email.com',
                          disable_user_emails: false)
    @upcoming = FactoryGirl.create(:valid_reservation,
                                   start_date: Time.zone.today,
                                   due_date: Time.zone.today + 1)
    @not_upcoming = FactoryGirl.create(:valid_reservation,
                                       start_date: Time.zone.today + 1,
                                       due_date: Time.zone.today + 2)
  end

  it 'sends emails for reservations that start today' do
    allow(@ac).to receive(:upcoming_checkout_email_active?).and_return(true)
    expect { subject.invoke }.to \
      change { ActionMailer::Base.deliveries.count }.by(1)
  end

  it "doesn't send emails when upcoming_checkout_email_active is false" do
    allow(@ac).to receive(:upcoming_checkout_email_active?).and_return(false)
    expect { subject.invoke }.not_to \
      change { ActionMailer::Base.deliveries.count }
  end
end
