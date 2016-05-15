require 'spec_helper'

# see http://robots.thoughtbot.com/test-rake-tasks-like-a-boss
describe 'email_overdue_reminder' do
  include_context 'rake'

  before(:each) do
    @ac = mock_app_config(admin_email: 'admin@email.com',
                          disable_user_emails: false)
    @overdue = FactoryGirl.build(:overdue_reservation)
    @overdue.save(validate: false)
    @not_overdue = FactoryGirl.create(:checked_out_reservation)
  end

  it 'sends emails for reservations that are overdue' do
    allow(@ac).to receive(:overdue_checkin_email_active?).and_return(true)
    expect { subject.invoke }.to \
      change { ActionMailer::Base.deliveries.count }.by(1)
  end

  it "doesn't send emails when overdue_checkin_email_active is false" do
    allow(@ac).to receive(:overdue_checkin_email_active?).and_return(false)
    expect { subject.invoke }.not_to \
      change { ActionMailer::Base.deliveries.count }
  end
end
