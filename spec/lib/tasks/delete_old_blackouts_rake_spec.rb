require 'spec_helper'

# see http://robots.thoughtbot.com/test-rake-tasks-like-a-boss
describe 'delete_old_blackouts' do
  include_context 'rake'

  before(:each) do
    @ac = mock_app_config
    allow(AppConfig).to receive(:blank?).and_return(false)
    @old = FactoryGirl.create(:blackout,
                              start_date: Time.zone.today - 11.days,
                              end_date: Time.zone.today - 10.days)
    @current = FactoryGirl.create(:blackout)
  end

  it "doesn't do anything when the res_exp_time parameter isn't set" do
    allow(@ac).to receive(:blackout_exp_time).and_return(nil)
    expect { subject.invoke }.not_to change { Blackout.count }
  end

  it 'deletes reservations older than the threshhold' do
    allow(@ac).to receive(:blackout_exp_time).and_return(5)
    expect { subject.invoke }.to change { Blackout.count }.by(-1)
  end

  it "doesn't delete reservations within threshhold" do
    allow(@ac).to receive(:blackout_exp_time).and_return(15)
    expect { subject.invoke }.not_to change { Blackout.count }
  end
end
