# frozen_string_literal: true
require 'spec_helper'

describe ReservationCreator do
  let!(:current_user) { UserMock.new }
  describe 'create!' do
    shared_examples 'successful create' do |cart:, **attrs|
      it do
        creator = ReservationCreator.new(cart: instance_spy('Cart', **cart),
                                         current_user: current_user,
                                         **attrs)
        results = creator.create!
        expect(results[:result]).to be_truthy
      end
    end
    shared_examples 'needs notes' do |cart:, **attrs|
      it do
        creator = ReservationCreator.new(cart: instance_spy('Cart', **cart),
                                         current_user: current_user,
                                         **attrs)
        results = creator.create!
        expect(results[:result]).to be_nil
        expect(results[:error]).to eq('needs notes')
      end
    end
    shared_examples 'unable to create' do |cart:, error: nil, **attrs|
      it do
        creator = ReservationCreator.new(cart: instance_spy('Cart', **cart),
                                         current_user: current_user,
                                         **attrs)
        results = creator.create!
        expect(results[:result]).to be_nil
        expect(results[:error]).to eq(error)
      end
    end
    context 'without errors' do
      it_behaves_like 'successful create', cart: { validate_all: '' }
    end
    context 'with errors' do
      context 'with notes' do
        it_behaves_like 'successful create', notes: 'note',
                                             cart: { validate_all: 'error' }
      end
      context 'without notes' do
        it_behaves_like 'needs notes', cart: { validate_all: 'error' }
      end
      context 'requests disabled' do
        before { mock_app_config(disable_requests: true) }
        it_behaves_like 'unable to create', cart: { validate_all: 'error' },
                                            error: 'requests disabled',
                                            notes: 'note'
      end
    end
  end
end
