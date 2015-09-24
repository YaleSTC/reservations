require 'spec_helper'

# see http://robots.thoughtbot.com/test-rake-tasks-like-a-boss
describe 'delete_old_blackouts' do
  include_context 'rake'

  before(:all) { FactoryGirl.create(:app_config) }

  before(:each) do
    @old = FactoryGirl.create(:blackout,
                              start_date: Time.zone.today - 11.days,
                              end_date: Time.zone.today - 10.days)
    @current = FactoryGirl.create(:blackout)
  end

  it "doesn't do anything when the res_exp_time parameter isn't set" do
    AppConfig.first.update_attributes(blackout_exp_time: nil)
    expect(AppConfig.first.blackout_exp_time).to be_nil
    expect { subject.invoke }.not_to change { Blackout.count }
  end

  it 'deletes reservations older than the threshhold' do
    AppConfig.first.update_attributes(blackout_exp_time: 5)
    expect(AppConfig.first.blackout_exp_time).to eq(5)
    expect { subject.invoke }.to change { Blackout.count }.by(-1)
  end

  it "doesn't delete reservations within threshhold" do
    AppConfig.first.update_attributes(blackout_exp_time: 15)
    expect(AppConfig.first.blackout_exp_time).to eq(15)
    expect { subject.invoke }.not_to change { Blackout.count }
  end
end
