# frozen_string_literal: true

require 'spec_helper'

describe 'Reservations archiving', type: :feature do
  before(:each) do
    @res = FactoryGirl.create(:valid_reservation)
  end

  shared_examples_for 'cannot see archive button' do
    it do
      visit reservation_path(@res)
      expect(page).not_to have_link('Archive Reservation')
    end
  end

  shared_examples_for 'can archive reservation' do
    before { visit reservation_path(@res) }
    it 'can see button' do
      expect(page).to have_link('Archive Reservation')
    end

    it '', js: true do
      accept_prompt(with: 'reason') { click_link 'Archive Reservation' }
      expect(page).to have_content 'Reservation successfully archived.'
    end
  end

  context 'as patron' do
    before { sign_in_as_user @user }
    after { sign_out }
    it_behaves_like 'cannot see archive button'
  end

  context 'as checkout person' do
    before { sign_in_as_user @checkout_person }
    after { sign_out }
    it_behaves_like 'cannot see archive button'
  end

  context 'as admin' do
    before { sign_in_as_user @admin }
    after { sign_out }
    it_behaves_like 'can archive reservation'

    context 'with equipment item' do
      before do
        @ei = FactoryGirl.create(:equipment_item,
                                 equipment_model: @res.equipment_model)
        procedures = instance_spy(ActionController::Parameters, to_h: {})
        @res.checkout(@ei.id, @admin, procedures, '').save
      end

      it_behaves_like 'can archive reservation'

      context 'with auto-deactivate enabled' do
        before do
          allow(@app_config).to receive(:autodeactivate_on_archive)
            .and_return(true)
        end

        it 'autodeactivates the equipment item', js: true do
          visit reservation_path(@res)

          accept_prompt(with: 'reason') { click_link 'Archive Reservation' }
          expect(page).to have_content 'has been automatically deactivated'
          visit equipment_item_path(@ei)
          expect(page).to have_content('reason')
          expect(page).to have_content('Status: Deactivated (reason)')
        end
      end

      context 'without auto-deactivate enabled', js: true do
        before do
          allow(@app_config).to receive(:autodeactivate_on_archive)
            .and_return(false)
        end

        it 'does not autodeactivate the equipment item' do
          visit reservation_path(@res)

          accept_prompt(with: 'reason') { click_link 'Archive Reservation' }
          expect(page).not_to have_content 'has been automatically deactivated'
          visit equipment_item_path(@ei)
          expect(page).to have_content('Status: available')
        end
      end

      context 'if checked in' do
        before do
          procedures = instance_spy(ActionController::Parameters, to_h: {})
          @res.checkin(@admin, procedures, '').save
        end

        it_behaves_like 'cannot see archive button'
      end
    end
  end
end
