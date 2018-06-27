# frozen_string_literal: true

require 'spec_helper'

describe 'Equipment Model editing', type: :feature do
  let(:eq_model) { FactoryGirl.create(:equipment_model) }

  before { sign_in_as_user(@admin) }
  after { sign_out }

  it 'works for checkout procedures', js: true do
    visit edit_equipment_model_path(eq_model)
    find_link('Add Step', match: :first).click
    task_input =
      'input[id^="equipment_model_checkout_procedures_attributes_"]'\
      '[id$="_step"]'
    find(task_input, match: :first).set('Checkout Task 1')
    click_on 'Update Equipment model'
    expect(page).to have_content('Checkout Task 1')
  end
  it 'works for checkin procedures', js: true do
    visit edit_equipment_model_path(eq_model)
    all(:link, 'Add Step').last.click
    task_input =
      'input[id^="equipment_model_checkin_procedures_attributes_"]'\
      '[id$="_step"]'
    find(task_input, match: :first).set('Checkin Task 1')
    click_on 'Update Equipment model'
    expect(page).to have_content('Checkin Task 1')
  end
end
