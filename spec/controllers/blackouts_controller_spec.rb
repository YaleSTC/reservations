# frozen_string_literal: true
require 'spec_helper'

describe BlackoutsController, type: :controller do
  before(:each) { mock_app_config }

  context 'with admin' do
    before { mock_user_sign_in(UserMock.new(:admin)) }

    describe 'GET index' do
      before do
        allow(Blackout).to receive(:all).and_return(Blackout.none)
        get :index
      end
      it_behaves_like 'successful request', :index
      it 'gets all blackouts' do
        expect(Blackout).to have_received(:all).at_least(:once)
      end
    end

    describe 'GET show' do
      context 'single blackout' do
        it 'does not try to get a set' do
          blackout = BlackoutMock.new(traits: [:findable], set_id: nil)
          allow(Blackout).to receive(:where)
          get :show, id: blackout.id
          expect(Blackout).not_to have_received(:where)
        end
      end
      context 'recurring blackout' do
        it 'gets the set' do
          blackout = BlackoutMock.new(traits: [:findable], set_id: 1)
          allow(Blackout).to receive(:where)
          get :show, id: blackout.id
          expect(Blackout).to have_received(:where)
            .with('set_id = ?', blackout.set_id)
        end
      end
    end

    describe 'GET new' do
      before do
        allow(Blackout).to receive(:new)
        get :new
      end
      it 'uses the appropriate date defaults' do
        expect(Blackout).to have_received(:new)
          .with(start_date: Time.zone.today, end_date: Time.zone.today + 1.day)
      end
      it_behaves_like 'successful request', :new
    end

    describe 'GET new_recurring' do
      before do
        allow(Blackout).to receive(:new)
        get :new_recurring
      end
      it 'uses the appropriate date defaults' do
        expect(Blackout).to have_received(:new)
          .with(start_date: Time.zone.today, end_date: Time.zone.today + 1.day)
      end
      it_behaves_like 'successful request', :new_recurring
    end

    describe 'POST create_recurring' do
      context 'with correct params' do
        let!(:blackout) { BlackoutMock.new(valid?: true) }
        before do
          allow(Blackout).to receive(:new).and_return(blackout)
          allow(Blackout).to receive(:create_blackout_set)
          post :create_recurring, blackout: { days: ['1', ''] }
        end
        it 'creates a set' do
          expect(Blackout).to have_received(:create_blackout_set)
        end
        it { is_expected.to redirect_to(blackouts_path) }
        it { is_expected.to set_flash[:notice] }
      end
      context 'with incorrect params' do
        before do
          request.env['HTTP_REFERER'] = 'where_i_came_from'
          post :create_recurring, blackout: { days: [''] }
        end
        it { is_expected.to set_flash[:error] }
        it { is_expected.to render_template('new_recurring') }
      end
      context 'with error during creation' do
        let!(:blackout) { BlackoutMock.new(valid?: true) }
        before do
          allow(Blackout).to receive(:new).and_return(blackout)
          allow(Blackout).to receive(:create_blackout_set).and_return('ERROR')
          post :create_recurring, blackout: { days: ['1', ''] }
        end
        it { is_expected.to set_flash[:error] }
        it { is_expected.to render_template('new_recurring') }
      end
    end

    context 'POST create' do
      context 'successful creation' do
        let!(:blackout) { FactoryGirl.build_stubbed(:blackout) }
        before do
          allow(Blackout).to receive(:new).and_return(blackout)
          allow(blackout).to receive(:save).and_return(true)
          post :create, blackout: { id: 1 }
        end
        it { is_expected.to redirect_to(blackout) }
        it { is_expected.to set_flash[:notice] }
      end
      context 'failed creation' do
        context 'failed save' do
          let!(:blackout) { BlackoutMock.new(save: false) }
          before do
            allow(Blackout).to receive(:new).and_return(blackout)
            post :create, blackout: { id: 1 }
          end
          it { is_expected.to render_template(:new) }
          it { is_expected.to set_flash[:error] }
        end
        context 'overlapping reservations' do
          let!(:blackout) { BlackoutMock.new(save: true) }
          before do
            allow(Blackout).to receive(:new).and_return(blackout)
            allow(Reservation).to \
              receive_message_chain(:overlaps_with_date_range, :active)
              .and_return(instance_spy('Array', empty?: false))
            post :create, blackout: { id: 1 }
          end
          it { is_expected.to render_template(:new) }
          it { is_expected.to set_flash[:error] }
        end
      end
    end

    describe 'PUT update' do
      context 'successful update' do
        let!(:blackout) { FactoryGirl.build_stubbed(:blackout) }
        before do
          allow(Blackout).to receive(:find)
          allow(Blackout).to receive(:find)
            .with(blackout.id.to_s).and_return(blackout)
          allow(blackout).to receive(:update_attributes).and_return(true)
          allow(blackout).to receive(:set_id=)
          put :update, id: blackout.id, blackout: { id: 1 }
        end
        it { is_expected.to redirect_to(blackout) }
        it { is_expected.to set_flash[:notice] }
        it 'deletes the set_id' do
          expect(blackout).to have_received(:set_id=).with(nil)
        end
      end
      context 'unsuccessful update' do
        let!(:blackout) { BlackoutMock.new(traits: [:findable]) }
        before do
          allow(blackout).to receive(:update_attributes).and_return(false)
          put :update, id: blackout.id, blackout: { id: 1 }
        end
        it { is_expected.to render_template(:edit) }
        it 'deletes the set_id' do
          expect(blackout).to have_received(:set_id=).with(nil)
        end
      end
    end

    describe 'DELETE destroy' do
      let!(:blackout) { BlackoutMock.new(traits: [:findable]) }
      before { delete :destroy, id: blackout.id }
      it 'deletes the blackout' do
        expect(blackout).to have_received(:destroy).with(:force)
      end
      it { is_expected.to redirect_to(blackouts_path) }
    end

    describe 'DELETE destroy recurring' do
      let!(:blackout) { BlackoutMock.new(traits: [:findable], set_id: 1) }
      before do
        allow(Blackout).to receive(:where)
          .with('set_id = ?', 1).and_return([blackout])
        delete :destroy_recurring, id: blackout.id
      end
      it 'deletes the whole set' do
        expect(blackout).to have_received(:destroy).with(:force)
      end
      it { is_expected.to set_flash[:notice] }
      it { is_expected.to redirect_to(blackouts_path) }
    end
  end

  context 'is not admin' do
    before { mock_user_sign_in }
    context 'GET index' do
      before { get :index }
      it_behaves_like 'redirected request'
    end
    context 'GET show' do
      before { get :show, id: 1 }
      it_behaves_like 'redirected request'
    end
    context 'POST create' do
      before { post :create, blackout: { id: 1 } }
      it_behaves_like 'redirected request'
    end
    context 'PUT update' do
      before { put :update, id: 1 }
      it_behaves_like 'redirected request'
    end
    context 'POST create recurring' do
      before { post :create_recurring, blackout: { id: 1 } }
      it_behaves_like 'redirected request'
    end
    context 'DELETE destroy' do
      before { delete :destroy, id: 1 }
      it_behaves_like 'redirected request'
    end
    context 'DELETE destroy recurring' do
      before { delete :destroy_recurring, id: 1 }
      it_behaves_like 'redirected request'
    end
  end
end
