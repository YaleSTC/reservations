# frozen_string_literal: true
require 'spec_helper'

describe DeleteOldBlackoutsJob, type: :job do
  it "doesn't run when the res_exp_time parameter isn't set" do
    mock_app_config(blackout_exp_time: nil)
    allow(described_class).to receive(:run)
    described_class.perform_now
    expect(described_class).not_to have_received(:run)
  end

  describe '#run' do
    it 'deletes blackouts' do
      mock_app_config(blackout_exp_time: 5)
      blackout = instance_spy('blackout')
      allow(Blackout).to receive(:where).and_return([blackout])
      described_class.perform_now
      expect(blackout).to have_received(:destroy)
    end
    it 'logs deletions' do
      mock_app_config(blackout_exp_time: 5)
      blackout = instance_spy('blackout')
      allow(Blackout).to receive(:where).and_return([blackout])
      allow(Rails.logger).to receive(:info)
      described_class.perform_now
      expect(Rails.logger).to have_received(:info)
        .with("Deleting old blackout:\n #{blackout.inspect}").once
    end
  end
end
