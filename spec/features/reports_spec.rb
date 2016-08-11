require 'spec_helper'

describe 'Reports', type: :feature do
  describe 'default index' do
    it 'shows a year from today' do
      sign_in_as_user FactoryGirl.create(:superuser)
      visit reports_path
      expect(page).to have_content(Time.zone.today.strftime("%b %d, %Y"))
      expect(page).to \
        have_content((Time.zone.today - 1.year).strftime("%b %d, %Y"))
    end
    it 'shows equipment model data' do
      model = FactoryGirl.create(:equipment_model)
      FactoryGirl.create(:checked_out_reservation, equipment_model: model)
      sign_in_as_user FactoryGirl.create(:superuser)
      visit reports_path
      within(:xpath, "//div[@id='equipment_models']/table/tbody/tr[1]") do
        within(:xpath, "./td[1]") { expect(page).to have_content(model.name) }
        # first row, checked_out column
        within(:xpath, "./td[4]") { expect(page).to have_content('1') }
      end
    end
    it 'shows category data' do
      model = FactoryGirl.create(:equipment_model)
      FactoryGirl.create(:checked_out_reservation, equipment_model: model)
      cat = model.category
      sign_in_as_user FactoryGirl.create(:superuser)
      visit reports_path
      within(:xpath, "//div[@id='categories']/table/tbody/tr[1]") do
        within(:xpath, "./td[1]") { expect(page).to have_content(cat.name) }
        # first row, checked_out column
        within(:xpath, "./td[4]") { expect(page).to have_content('1') }
      end
    end
  end
  
  describe 'can change dates' do
    it '', js: true do
      sign_in_as_user FactoryGirl.create(:superuser)
      visit reports_path
      start_time = Time.zone.today - 1.month
      end_time = Time.zone.today - 1.week
      fill_in('report_start_date', with: start_time.strftime('%m/%d/%Y'))
      fill_in('report_end_date', with: end_time.strftime('%m/%d/%Y'))
      click_on 'Generate Report'
      expect(page).to have_content(start_time.strftime("%b %d, %Y"))
      expect(page).to have_content(end_time.strftime("%b %d, %Y"))
    end
  end
end
