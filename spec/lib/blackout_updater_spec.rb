# frozen_string_literal: true

require 'spec_helper'

describe BlackoutUpdater do
  describe 'update!' do
    context 'without errors' do
      it 'successfully updates the blackout' do
        blackout = instance_spy(Blackout, save: true,
                                          validate: true)
        allow(Reservation).to receive_message_chain(:affected_by_blackout,
                                                    :active).and_return([])
        updater = BlackoutUpdater.new(blackout: blackout, params: {})
        updater.update
        expect(blackout).to have_received(:save)
      end
      it 'returns success message' do
        blackout = instance_spy(Blackout, save: true,
                                          validate: true)
        allow(Reservation).to receive_message_chain(:affected_by_blackout,
                                                    :active).and_return([])
        updater = BlackoutUpdater.new(blackout: blackout, params: {})
        results = updater.update
        expect(results[:result]).to eq('Blackout was successfully updated.')
      end
      it 'does not return an error' do
        blackout = instance_spy(Blackout, save: true,
                                          validate: true)
        allow(Reservation).to receive_message_chain(:affected_by_blackout,
                                                    :active).and_return([])
        updater = BlackoutUpdater.new(blackout: blackout, params: {})
        results = updater.update
        expect(results[:error]).to be_nil
      end
    end
    context 'with errors' do
      context 'with conflicting reservation' do
        it 'does not update blackout' do
          blackout = instance_spy(Blackout, save: true,
                                            validate: true)
          cf = instance_spy('Reservation', md_link: 'Dummy conflict')
          allow(Reservation).to receive_message_chain(:affected_by_blackout,
                                                      :active).and_return([cf])
          updater = BlackoutUpdater.new(blackout: blackout, params: {})
          updater.update
          expect(blackout).not_to have_received(:update_attributes)
        end
        it 'does not return a result' do
          blackout = instance_spy(Blackout, save: true,
                                            validate: true)
          cf = instance_spy('Reservation', md_link: 'Dummy conflict')
          allow(Reservation).to receive_message_chain(:affected_by_blackout,
                                                      :active).and_return([cf])
          updater = BlackoutUpdater.new(blackout: blackout, params: {})
          results = updater.update
          expect(results[:result]).to be_nil
        end
        it 'returns an error' do
          blackout = instance_spy(Blackout, save: true,
                                            validate: true)
          cf = instance_spy('Reservation', md_link: 'Dummy conflict')
          allow(Reservation).to receive_message_chain(:affected_by_blackout,
                                                      :active).and_return([cf])
          updater = BlackoutUpdater.new(blackout: blackout, params: {})
          results = updater.update
          expect(results[:error]).to include('Dummy conflict')
        end
      end
      context 'with invalid blackout' do
        it 'tries to update blackout' do
          blackout = instance_spy(Blackout, save: false,
                                            validate: false)
          allow(Reservation).to receive_message_chain(:affected_by_blackout,
                                                      :active).and_return([])
          allow(blackout).to receive_message_chain(:errors, :full_messages)
            .and_return('Dummy error message')
          updater = BlackoutUpdater.new(blackout: blackout, params: {})
          updater.update
          expect(blackout).to have_received(:save)
        end
        it 'does not return a result' do
          blackout = instance_spy(Blackout, save: false,
                                            validate: false)
          allow(Reservation).to receive_message_chain(:affected_by_blackout,
                                                      :active).and_return([])
          allow(blackout).to receive_message_chain(:errors, :full_messages)
            .and_return('Dummy error message')
          updater = BlackoutUpdater.new(blackout: blackout, params: {})
          results = updater.update
          expect(results[:result]).to be_nil
        end
        it 'returns an error' do
          blackout = instance_spy(Blackout, save: false,
                                            validate: false)
          allow(Reservation).to receive_message_chain(:affected_by_blackout,
                                                      :active).and_return([])
          allow(blackout).to receive_message_chain(:errors, :full_messages)
            .and_return('Dummy error message')
          updater = BlackoutUpdater.new(blackout: blackout, params: {})
          results = updater.update
          expect(results[:error]).to eq('Dummy error message')
        end
      end
    end
  end
end
