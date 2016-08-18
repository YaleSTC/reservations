# frozen_string_literal: true
require 'spec_helper'

shared_examples_for 'email job' do |ac_setting, scope|
  it 'sends emails' do
    mock_app_config(ac_setting)
    res = ReservationMock.new
    allow(Reservation).to receive(scope).and_return([res])
    expect(UserMailer).to \
      receive_message_chain(:reservation_status_update, :deliver_now)
    described_class.perform_now
  end

  it 'gets the appropriate reservations' do
    mock_app_config(ac_setting)
    allow(Reservation).to receive(scope).and_return([])
    described_class.perform_now
    expect(Reservation).to have_received(scope)
  end

  it 'logs emails' do
    mock_app_config(ac_setting)
    res = ReservationMock.new
    allow(Reservation).to receive(scope).and_return([res])
    allow(Rails.logger).to receive(:info)
    described_class.perform_now
    expect(Rails.logger).to have_received(:info).at_least(:once)
  end

  it "doesn't send emails when disabled" do
    allow(described_class).to receive(:run)
    described_class.perform_now
    expect(described_class).not_to have_received(:run)
  end
end
