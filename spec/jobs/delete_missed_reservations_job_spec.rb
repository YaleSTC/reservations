# frozen_string_literal: true
require 'spec_helper'

describe DeleteMissedReservationsJob, type: :job do
  it "doesn't run when the res_exp_time parameter isn't set" do
    mock_app_config(res_exp_time: nil)
    allow(described_class).to receive(:run)
    described_class.perform_now
    expect(described_class).not_to have_received(:run)
  end

  it 'collects the appropriate reservations' do
    mock_app_config(res_exp_time: 5)
    allow(Reservation).to receive(:deletable_missed).and_return([])
    described_class.perform_now
    expect(Reservation).to have_received(:deletable_missed)
  end

  describe '#run' do
    it 'deletes reservations' do
      mock_app_config(res_exp_time: 5)
      res = ReservationMock.new
      allow(Reservation).to receive(:deletable_missed).and_return([res])
      described_class.perform_now
      expect(res).to have_received(:destroy)
    end

    it 'logs deletions' do
      mock_app_config(res_exp_time: 5)
      res = ReservationMock.new
      allow(Reservation).to receive(:deletable_missed).and_return([res])
      allow(Rails.logger).to receive(:info)
      described_class.perform_now
      expect(Rails.logger).to have_received(:info)
        .with("Deleting reservation:\n #{res.inspect}").once
    end
  end
end
