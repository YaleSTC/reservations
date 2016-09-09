# frozen_string_literal: true
require 'spec_helper'

RSpec.feature 'Equipment model calendar view' do
  context 'as admin or superuser' do
    before(:each) { sign_in_as_user(@admin) }
    after(:each) { sign_out }

    it 'has useful links' do
      visit calendar_equipment_model_path(@eq_model)

      expect(page).to \
        have_css "input[type=submit][value='Export Calendar']"
      expect(page).to have_link "Back to #{@eq_model.name}",
                                href: equipment_model_path(@eq_model)
    end

    it 'shows all reservations in the current month', :js do
      create_res_in_current_month(2)

      visit calendar_equipment_model_path(@eq_model)

      expect(page).to have_css '[data-role=cal-item]', count: 2
    end

    it 'does not show reservations next month', :js do
      create_res_in_current_month
      FactoryGirl.create(:valid_reservation,
                         start_date: Time.zone.today + 1.month,
                         due_date: Time.zone.today + 1.month + 1.day)

      visit calendar_equipment_model_path(@eq_model)

      expect(page).to have_css '[data-role=cal-item]', count: 1
    end

    it 'links to the reservation', :js do
      res = create_res_in_current_month

      visit calendar_equipment_model_path(@eq_model)

      # this is super hacky, but the url host was super weird (127.0.0.1:37353)
      expect(page.find('[data-role=cal-item]')[:href]).to \
        include reservation_path(res) + '.html'
    end
  end

  context 'as non-admin' do
    shared_examples 'fails' do
      it 'redirects to catalog' do
        visit calendar_equipment_model_path(@eq_model)

        expect(page).to have_css 'h1', text: 'Catalog'
      end
    end

    context 'as checkout person' do
      before(:each) { sign_in_as_user(@checkout_person) }
      after(:each) { sign_out }

      it_behaves_like 'fails'
    end

    context 'as patron' do
      before(:each) { sign_in_as_user(@user) }
      after(:each) { sign_out }

      it_behaves_like 'fails'
    end

    context 'as banned user' do
      before(:each) { sign_in_as_user(@banned) }
      after(:each) { sign_out }

      it_behaves_like 'fails'
    end
  end

  def create_res_in_current_month(count = 1)
    raise ArgumentError if count > 28
    day0 = Time.zone.today.beginning_of_month # to ensure it's in this month
    (1..count).each do |i|
      # make sure it's a 1-day reservation so there's only a single cell
      # (avoid weekend overlaps)
      res = build :reservation, equipment_model: @eq_model,
                                start_date: day0 + (i - 1).days,
                                due_date: day0 + (i - 1).days,
                                status: Reservation.statuses[:reserved]
      res.save(validate: false)
      return res if i == count # return last reservation if you want it
    end
  end
end
