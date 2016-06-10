# frozen_string_literal: true
require 'spec_helper'

describe EmailMissedReservationsJob, type: :job do
  it_behaves_like 'email job',
                  { send_notifications_for_deleted_missed_reservations: true },
                  :missed_not_emailed
  it 'sets the missed_email_sent flag' do
    mock_app_config(send_notifications_for_deleted_missed_reservations: true)
    res = ReservationMock.new
    allow(Reservation).to receive(:missed_not_emailed).and_return([res])
    allow(UserMailer).to \
      receive_message_chain(:reservation_status_update, :deliver_now)
    described_class.perform_now
    expect(res).to have_received(:flag).with(:missed_email_sent)
    expect(res).to have_received(:save!)
  end
end
