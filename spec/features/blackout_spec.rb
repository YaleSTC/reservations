require 'spec_helper'

describe 'Blackouts', type: :feature do
  describe 'creation' do
    before { sign_in_as_user @superuser }
    context 'normal' do
      it 'succeeds' do
        visit blackouts_path
        click_on 'New Blackout'
        select('Blackout', from: 'blackout_blackout_type')
        fill_in('blackout_notice', with: 'NOTICE')
        click_on 'Create Blackout'
        expect(Blackout.where(notice: 'NOTICE')).not_to be_empty
      end
    end
    context 'recurring' do
      it 'succeeds' do
        visit blackouts_path
        click_on 'New Recurring Blackout'
        check('blackout_days_6')
        select('Blackout', from: 'blackout_blackout_type')
        fill_in('blackout_notice', with: 'NOTICE')
        click_on 'Create Blackout'
        expect(Blackout.where(notice: 'NOTICE')).not_to be_empty
      end
    end
  end
  context 'hard blackouts' do
    before { sign_in_as_user @user }
    it 'prevents new reservations' do
      @blackout = FactoryGirl.create(:blackout)
      visit equipment_model_path(EquipmentModel.first)
      click_on 'Add to Cart'
      click_on 'Reserve'
      expect(page).to have_content 'Confirm Reservation Request'
    end
  end
end
