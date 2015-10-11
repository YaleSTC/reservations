require 'spec_helper'

# see http://robots.thoughtbot.com/test-rake-tasks-like-a-boss
describe 'flag_overdue' do
  include_context 'rake'

  before(:all) { FactoryGirl.create(:app_config) }

  before(:each) { @res = FactoryGirl.create(:valid_reservation) }

  it 'flags reservations due yesterday as overdue' do
    @res.update_attributes(
      FactoryGirl.attributes_for(:overdue_reservation))
    @res.update_attributes(overdue: false)
    expect { subject.invoke }.to(
      change { Reservation.find(@res.id).overdue }.from(false).to(true))
  end

  it "doesn't flag not overdue reservations" do
    expect { subject.invoke }.not_to(
      change { Reservation.find(@res.id).overdue })
  end

  it 'flags past overdue reservations' do
    old_res = FactoryGirl.build(:overdue_reservation)
    old_res.assign_attributes(start_date: Time.zone.today - 7.days,
                              due_date: Time.zone.today - 6.days,
                              overdue: false)
    old_res.save!(validate: false)

    expect { subject.invoke }.to \
      change { Reservation.find(old_res.id).overdue }
  end
end

describe 'flag_missed' do
  include_context 'rake'

  before(:all) { FactoryGirl.create(:app_config) }

  before(:each) { @res = FactoryGirl.create(:valid_reservation) }

  it 'flags missed reservations as missed' do
    @res.update_attributes(start_date: Time.zone.yesterday,
                           due_date: Time.zone.today)
    expect { subject.invoke }.to(
      change { Reservation.find(@res.id).status }.from('reserved').to('missed'))
  end

  it "doesn't flag not missed reservations" do
    expect { subject.invoke }.not_to change { Reservation.find(@res.id).status }
  end

  it "doesn't flag checked out reservations" do
    @res.update_attributes(
      FactoryGirl.attributes_for(:checked_out_reservation))
    expect { subject.invoke }.not_to change { Reservation.find(@res.id).status }
  end
end

describe 'deny_missed_requests' do
  include_context 'rake'

  before(:all) { FactoryGirl.create(:app_config) }

  before(:each) { @res = FactoryGirl.create(:valid_reservation) }

  it 'flags missed requests as denied and expired' do
    @res.update_attributes(FactoryGirl.attributes_for(:request))
    @res.update_attributes(start_date: Time.zone.yesterday,
                           due_date: Time.zone.today)
    expect { subject.invoke }.to(
      change { Reservation.find(@res.id).status }.from(
        'requested').to('denied'))
    expect(Reservation.find(@res.id).flagged?(:expired)).to be_truthy
  end

  it "doesn't flag missed non-requests" do
    @res.update_attributes(
      FactoryGirl.attributes_for(:missed_reservation))
    expect { subject.invoke }.not_to change { Reservation.find(@res.id).status }
  end

  it "doesn't flag not missed requests" do
    @res.update_attributes(FactoryGirl.attributes_for(:request))
    expect { subject.invoke }.not_to change { Reservation.find(@res.id).status }
  end

  it 'sends appropriate emails' do
    @res.update_attributes(FactoryGirl.attributes_for(:request))
    @res.update_attributes(start_date: Time.zone.yesterday,
                           due_date: Time.zone.today)
    @no_email = FactoryGirl.create(:missed_reservation)
    expect { subject.invoke }.to(
      change { ActionMailer::Base.deliveries.count }.by(1))
  end
end
