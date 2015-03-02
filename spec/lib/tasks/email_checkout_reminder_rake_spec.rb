require 'spec_helper'

# see http://robots.thoughtbot.com/test-rake-tasks-like-a-boss
describe 'email_checkout_reminder' do
  include_context 'rake'

  before(:all) { FactoryGirl.create(:app_config) }

  before(:each) do
    @upcoming = FactoryGirl.create(:valid_reservation,
                                   start_date: Time.zone.today,
                                   due_date: Time.zone.today + 1)
    @not_upcoming = FactoryGirl.create(:valid_reservation,
                                       start_date: Time.zone.today + 1,
                                       due_date: Time.zone.today + 2)
  end

  it 'sends emails for reservations that start today' do
    AppConfig.first.update_attributes(upcoming_checkout_email_active: true)
    expect(AppConfig.first.upcoming_checkout_email_active).to eq(true)
    expect { subject.invoke }.to(
      change { ActionMailer::Base.deliveries.count }.by(1))
  end

  it "doesn't send emails when upcoming_checkout_email_active is false" do
    AppConfig.first.update_attributes(upcoming_checkout_email_active: false)
    expect(AppConfig.first.upcoming_checkout_email_active).to eq(false)
    expect { subject.invoke }.not_to(
      change { ActionMailer::Base.deliveries.count })
  end
end
