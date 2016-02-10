require 'spec_helper'

# see http://robots.thoughtbot.com/test-rake-tasks-like-a-boss
describe 'email_checkin_reminder' do
  include_context 'rake'

  before(:all) { FactoryGirl.create(:app_config) }

  before(:each) do
    @upcoming = FactoryGirl.create(:checked_out_reservation,
                                   due_date: Time.zone.today)
    @not_upcoming = FactoryGirl.create(:valid_reservation,
                                       start_date: Time.zone.today + 1,
                                       due_date: Time.zone.today + 2)
  end

  it 'sends emails for checked-out reservations that end today' do
    AppConfig.first.update_attributes(upcoming_checkin_email_active: true)
    expect(AppConfig.first.upcoming_checkin_email_active).to eq(true)
    expect { subject.invoke }.to(
      change { ActionMailer::Base.deliveries.count }.by(1))
  end

  it "doesn't send emails for non-checked-out reservations that end today" do
    @upcoming.update_attributes(
      FactoryGirl.attributes_for(:valid_reservation,
                                 start_date: Time.zone.today - 1.day,
                                 due_date: Time.zone.today))
    AppConfig.first.update_attributes(upcoming_checkin_email_active: true)
    expect(AppConfig.first.upcoming_checkin_email_active).to eq(true)
    expect(@upcoming.reserved?).to be_truthy
    expect { subject.invoke }.not_to(
      change { ActionMailer::Base.deliveries.count })
  end
  it "doesn't send emails when upcoming_checkin_email_active is false" do
    AppConfig.first.update_attributes(upcoming_checkin_email_active: false)
    expect(AppConfig.first.upcoming_checkin_email_active).to eq(false)
    expect { subject.invoke }.not_to(
      change { ActionMailer::Base.deliveries.count })
  end
end
