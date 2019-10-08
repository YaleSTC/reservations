# frozen_string_literal: true

require 'spec_helper'

shared_examples_for 'flag job' do |attr, scope|
  it 'updates the reservations status' do
    res = ReservationMock.new
    allow(Reservation).to receive(scope).and_return([res])
    described_class.perform_now
    expect(res).to have_received(:update).with(attr)
  end
  it 'logs the update' do
    res = ReservationMock.new
    allow(Reservation).to receive(scope).and_return([res])
    allow(Rails.logger).to receive(:info)
    described_class.perform_now
    expect(Rails.logger).to have_received(:info).at_least(:once)
  end
  it 'collects the appropriate reservations' do
    allow(Reservation).to receive(scope).and_return([])
    described_class.perform_now
    expect(Reservation).to have_received(scope)
  end
end
