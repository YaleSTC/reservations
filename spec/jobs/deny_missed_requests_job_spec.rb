# frozen_string_literal: true
require 'spec_helper'

describe DenyMissedRequestsJob, type: :job do
  it_behaves_like 'email job', {}, :missed_requests
  it 'flags missed requests as denied and expired' do
    res = ReservationMock.new
    allow(Reservation).to receive(:missed_requests).and_return([res])
    allow(UserMailer).to \
      receive_message_chain(:reservation_status_update, :deliver_now)
    described_class.perform_now
    expect(res).to have_received(:expire!)
  end
end
