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
      expect(@res.reload.checked_out).not_to be_nil
      expect(@res.reload.checked_in).not_to be_nil
      expect(@res.reload.notes).to include('Archived')
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
        @res.checkout(@ei.id, @admin, [], '').save
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
          expect(@res.reload.checked_in).not_to be_nil
          expect(@ei.reload.deleted_at).not_to be_nil
          expect(@ei.reload.deactivation_reason).to include('reason')
          expect(page).to have_content 'has been automatically deactivated'
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
          expect(@res.reload.checked_in).not_to be_nil
          expect(@ei.reload.deleted_at).to be_nil
          expect(@ei.reload.deactivation_reason).to be_nil
          expect(page).not_to have_content 'has been deactivated'
        end
      end

      context 'if checked in' do
        before { @res.checkin(@admin, [], '').save }

        it_behaves_like 'cannot see archive button'
      end
    end
  end
end
