require 'spec_helper'

describe 'Procedures', type: :feature do
  context 'checkout procedure' do
    it 'allows checkout if checked' do
      model = FactoryGirl.create(:equipment_model)
      procedure = FactoryGirl.create(:checkout_procedure,
                                     equipment_model: model)
      res = FactoryGirl.create(:valid_reservation, equipment_model: model)
      sign_in_as_user(FactoryGirl.create(:admin))
      visit manage_reservations_for_user_path(res.reserver)
      select(model.equipment_items.first.name, from: 'Equipment Item')
      check(procedure.step)
      click_on 'Check-Out Equipment'
      expect(page).to have_content('Check-Out Receipt')
    end
    it 'notifies when not checked', js: true do
      model = FactoryGirl.create(:equipment_model)
      FactoryGirl.create(:checkout_procedure, equipment_model: model)
      res = FactoryGirl.create(:valid_reservation, equipment_model: model)
      sign_in_as_user(FactoryGirl.create(:admin))
      visit manage_reservations_for_user_path(res.reserver)
      select(model.equipment_items.first.name, from: 'Equipment Item')
      message = dismiss_confirm do
        click_on 'Check-Out Equipment'
      end
      expect(message).not_to be_nil
    end
  end

  context 'checkin procedure' do
    it 'allows checkin if checked' do
      model = FactoryGirl.create(:equipment_model)
      procedure = FactoryGirl.create(:checkin_procedure, equipment_model: model)
      res = FactoryGirl.create(:checked_out_reservation, equipment_model: model)
      sign_in_as_user(FactoryGirl.create(:admin))
      visit manage_reservations_for_user_path(res.reserver)
      check("reservations_#{res.id}_checkin_")
      check(procedure.step)
      click_on 'Check-In Equipment'
      expect(page).to have_content('Check-In Receipt')
    end
    # FIXME: can't find the checkbox with JS driver
    # tried: find_by_id, xpath
    # it 'notifies when not checked', js: true do
    #   model = FactoryGirl.create(:equipment_model)
    #   FactoryGirl.create(:checkin_procedure, equipment_model: model)
    #   res = FactoryGirl.create(:checked_out_reservation, equipment_model: model)
    #   sign_in_as_user(FactoryGirl.create(:admin))
    #   visit manage_reservations_for_user_path(res.reserver)
    #   check("reservations_#{res.id}_checkin_")
    #   message = dismiss_confirm do
    #     click_on 'Check-In Equipment'
    #   end
    #   expect(message).not_to be_nil
    # end
  end
end
