# frozen_string_literal: true

require 'spec_helper'

describe 'Blackout creation' do
  before do
    sign_in_as_user @admin
  end

  context 'with overlapping but unaffected reservations' do
    before do
      # This reservation will start before the blackout we try to create and end
      # afterwards - it should not prevent the blackout from being created.
      FactoryGirl.create(:equipment_item, equipment_model: @eq_model)
      FactoryGirl.create(:reservation, equipment_model: @eq_model,
                                       due_date: Time.zone.today + 1.month)
    end

    it 'works' do
      visit new_blackout_path
      fill_in_blackout_data(start_date: Time.zone.tomorrow,
                            end_date: Time.zone.tomorrow + 1.day)
      expect(page).to have_css('.alert-success', text: /successfully created./)
    end
  end

  context 'with affected reservation' do
    before do
      # This reservation's due date will fall within the blackout we try to
      # create so we want it to fail.
      FactoryGirl.create(:equipment_item, equipment_model: @eq_model)
      FactoryGirl.create(:reservation, equipment_model: @eq_model,
                                       due_date: Time.zone.today + 2.days)
    end

    it 'fails' do
      visit new_blackout_path
      fill_in_blackout_data(start_date: Time.zone.tomorrow,
                            end_date: Time.zone.tomorrow + 3.days)
      expect(page).to have_css('.alert-danger', text: /try again/)
    end
  end

  def fill_in_blackout_data(start_date:, end_date:)
    select 'Blackout', from: 'Blackout Type'
    fill_in_date(field: 'start', date: start_date)
    fill_in_date(field: 'end', date: end_date)
    fill_in 'Notice', with: 'Foo'
    click_on 'Create Blackout'
  end

  def fill_in_date(field:, date:)
    fill_in "blackout_#{field}_date", with: date
    find(:xpath, "//input[@id='date_#{field}_alt']", visible: :all)
      .set(date)
  end
end
