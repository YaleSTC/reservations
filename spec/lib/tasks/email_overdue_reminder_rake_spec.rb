require 'spec_helper'

# see http://robots.thoughtbot.com/test-rake-tasks-like-a-boss
describe 'email_overdue_reminder' do
  include_context 'rake'

  before(:all) { FactoryGirl.create(:app_config) }

  before(:each) do
    @overdue = FactoryGirl.build(:overdue_reservation)
    @overdue.save(validate: false)
    @not_overdue = FactoryGirl.create(:checked_out_reservation)
  end

  it 'sends emails for reservations that are overdue' do
    AppConfig.first.update_attributes(overdue_checkin_email_active: true)
    expect(AppConfig.first.overdue_checkin_email_active).to eq(true)
    expect { subject.invoke }.to(
      change { ActionMailer::Base.deliveries.count }.by(1))
  end

  it "doesn't send emails when overdue_checkin_email_active is false" do
    AppConfig.first.update_attributes(overdue_checkin_email_active: false)
    expect(AppConfig.first.overdue_checkin_email_active).to eq(false)
    expect { subject.invoke }.not_to(
      change { ActionMailer::Base.deliveries.count })
  end
end
