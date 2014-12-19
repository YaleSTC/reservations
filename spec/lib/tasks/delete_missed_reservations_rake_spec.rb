require 'spec_helper'

# see http://robots.thoughtbot.com/test-rake-tasks-like-a-boss
describe 'delete_missed_reservations' do
  include_context 'rake'

  before(:all) { FactoryGirl.create(:app_config) }

  before(:each) do
    @missed = FactoryGirl.create(:missed_reservation,
                                 start_date: Date.current - 11.days,
                                 due_date: Date.current - 10.days)
    @not_missed = FactoryGirl.create(:valid_reservation)
  end

  it "doesn't do anything when the res_exp_time parameter isn't set" do
    AppConfig.first.update_attributes(res_exp_time: nil)
    expect(AppConfig.first.res_exp_time).to be_nil
    expect { subject.invoke }.not_to change { Reservation.count }
  end

  it 'deletes reservations older than the threshhold' do
    AppConfig.first.update_attributes(res_exp_time: 5)
    expect(AppConfig.first.res_exp_time).to eq(5)
    expect { subject.invoke }.to change { Reservation.count }.by(-1)
  end

  it "doesn't delete reservations within threshhold" do
    AppConfig.first.update_attributes(res_exp_time: 15)
    expect(AppConfig.first.res_exp_time).to eq(15)
    expect { subject.invoke }.not_to change { Reservation.count }
  end
end
