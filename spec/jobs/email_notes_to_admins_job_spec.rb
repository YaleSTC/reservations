# frozen_string_literal: true
require 'spec_helper'

describe EmailNotesToAdminsJob, type: :job do
  def stub_scope_chain(res, *chain)
    final = chain.pop
    chain.each do |scope|
      allow(Reservation).to receive(scope).and_return(Reservation)
    end
    allow(Reservation).to receive(final).and_return(res)
  end

  shared_examples 'admin email' do |scope|
    it 'sends emails' do
      res = spy('Array', empty?: false)
      allow(Reservation).to receive(scope).and_return(res)
      allow(res).to receive(:notes_unsent).and_return(res)
      allow(res).to receive(:update_all)
      expect(AdminMailer).to \
        receive_message_chain(:notes_reservation_notification, :deliver_now)
      described_class.perform_now
    end
    it 'gets the appropriate reservations' do
      res = spy('Array', empty?: true)
      allow(Reservation).to receive(scope).and_return(res)
      allow(res).to receive(:notes_unsent).and_return(res)
      described_class.perform_now
      expect(Reservation).to have_received(scope)
      expect(res).to have_received(:notes_unsent)
    end
    it 'unsets the notes_unsent flag' do
      res = spy('Array', empty?: false)
      allow(Reservation).to receive(scope).and_return(res)
      allow(res).to receive(:notes_unsent).and_return(res)
      allow(AdminMailer).to \
        receive_message_chain(:notes_reservation_notification, :deliver_now)
      described_class.perform_now
      expect(res).to have_received(:update_all).with(notes_unsent: false)
    end
  end

  it_behaves_like 'admin email', :checked_out
  it_behaves_like 'admin email', :returned
end
