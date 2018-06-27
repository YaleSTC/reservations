# frozen_string_literal: true

require 'spec_helper'

describe 'Reservations handling', type: :feature do
  let(:eq_model) { FactoryGirl.create(:equipment_model_with_item) }

  before do
    sign_in_as_user(@admin)
  end
  after { sign_out }

  context 'with checkout procedure' do
    let!(:procedure) do
      FactoryGirl.create(:checkout_procedure, equipment_model_id: eq_model.id)
    end
    let!(:reservation) do
      FactoryGirl.create(:valid_reservation, reserver: @user,
                                             equipment_model: eq_model)
    end

    it 'works' do
      visit manage_reservations_for_user_path(@user)
      select eq_model.equipment_items.first.name.to_s, from: 'Equipment Item'
      check "reservations_#{reservation.id}_checkout_procedures_#{procedure.id}"
      click_button 'Check-Out Equipment'
      expect(page).to have_content 'Check-Out Receipt'
    end
  end

  context 'with checkin procedure' do
    let!(:procedure) do
      FactoryGirl.create(:checkin_procedure, equipment_model_id: eq_model.id)
    end
    let!(:reservation) do
      FactoryGirl.create(:checked_out_reservation, reserver: @user,
                                                   equipment_model: eq_model)
    end

    it 'works' do
      visit manage_reservations_for_user_path(@user)
      check "reservations_#{reservation.id}_checkin_"
      check "reservations_#{reservation.id}_checkin_procedures_#{procedure.id}"
      click_button 'Check-In Equipment'
      expect(page).to have_content 'Check-In Receipt'
    end
  end
end
