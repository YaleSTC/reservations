require 'spec_helper'

# see http://robots.thoughtbot.com/test-rake-tasks-like-a-boss
describe 'delete_missed_reservations' do
  include_context 'rake'

  before(:each) do
    @ac = mock_app_config(blank?: false)
    @missed = FactoryGirl.create(:missed_reservation,
                                 start_date: Time.zone.today - 11.days,
                                 due_date: Time.zone.today - 10.days)
    @not_missed = FactoryGirl.create(:valid_reservation)
  end

  it "doesn't do anything when the res_exp_time parameter isn't set" do
    allow(@ac).to receive(:res_exp_time).and_return(nil)
    expect { subject.invoke }.not_to change { Reservation.count }
  end

  it 'deletes reservations older than the threshhold' do
    allow(@ac).to receive(:res_exp_time).and_return(5)
    expect { subject.invoke }.to change { Reservation.count }.by(-1)
  end

  it "doesn't delete reservations within threshhold" do
    allow(@ac).to receive(:res_exp_time).and_return(15)
    expect { subject.invoke }.not_to change { Reservation.count }
  end
end
