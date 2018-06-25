# frozen_string_literal: true
require 'spec_helper'

describe 'Reservation Index', type: :feature do
  context 'as privileged user' do
    before { sign_in_as_user @admin }
    after { sign_out }
    it 'defaults to upcoming reservations' do
      upcoming = FactoryGirl.create(:upcoming_reservation)
      not_upcoming = FactoryGirl.create(:valid_reservation,
                                        start_date: Time.zone.today + 2.days,
                                        due_date: Time.zone.today + 3.days)
      visit reservations_path
      table_content = page.all('table#reservations-list td').map(&:text)
      expect(table_content).to include(upcoming.id.to_s)
      expect(table_content).not_to include(not_upcoming.id.to_s)
    end
    it 'defaults to reservations +/- one week from today' do
      start_date = (Time.zone.today - 1.week).strftime('%m/%d/%Y')
      end_date = (Time.zone.today + 1.week).strftime('%m/%d/%Y')
      visit reservations_path
      expect(page.find('#list_start_date').value).to eq(start_date)
      expect(page.find('#list_end_date').value).to eq(end_date)
    end
    it 'can be filtered by various statuses' do
      filters = %w(upcoming reserved requested checked_out overdue returned
                   returned_overdue archived approved_requests denied)
      filters.map! { |f| "/reservations?#{f}=true" }
      visit reservations_path
      nav_links = page.all('div.res_index_nav ul li a').map { |a| a[:href] }
      expect(nav_links).to match_array(filters)
    end
    it 'shows reserver in table' do
      visit reservations_path
      table_column_names = page.all('table#reservations-list th').map(&:text)
      expect(table_column_names).to include('Reserver')
    end
  end
  context 'as normal user' do
    before { sign_in_as_user @user }
    after { sign_out }
    it 'cannot be filtered to upcoming' do
      visit reservations_path
      nav_links = page.all('div.res_index_nav ul li a').map { |a| a[:href] }
      expect(nav_links).not_to include('/reservations?upcoming=true')
    end
    it 'only shows own reservations' do
      other = FactoryGirl.create(:valid_reservation, reserver: @admin)
      own = FactoryGirl.create(:valid_reservation, reserver: @user)
      visit reservations_path
      table_content = page.all('table#reservations-list td').map(&:text)
      expect(table_content).to include(own.id.to_s)
      expect(table_content).not_to include(other.id.to_s)
    end
  end
end
