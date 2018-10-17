# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Reservations::AffectedByRecurringBlackoutQuery do
  let!(:overdue) do
    create(:overdue_reservation, due_date: Time.zone.today - 1.day)
  end
  let!(:checked_out) do
    create(:checked_out_reservation, due_date: Time.zone.tomorrow)
  end
  let!(:no_problem) do
    create(:checked_out_reservation, due_date: Time.zone.today + 4.days)
  end
  let!(:archived) { create(:archived_reservation) }
  let!(:checked_in) { create(:checked_in_reservation) }
  let!(:reserved) do
    create(:valid_reservation,
           start_date: Time.zone.tomorrow,
           due_date: Time.zone.today + 2.days)
  end
  let!(:res_dates) do
    [Time.zone.tomorrow, Time.zone.tomorrow + 1.day]
  end

  it 'returns reservations which have due/start date in a blackout range' do
    expect(described_class.call(res_dates))
      .to match_array([reserved, checked_out])
  end

  it 'works with a custom relation passed in' do
    custom_relation = Reservation.where.not(id: checked_out.id)
    expect(described_class.new(custom_relation).call(res_dates))
      .to match_array([reserved])
  end
end
