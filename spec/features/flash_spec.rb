# frozen_string_literal: true

require 'spec_helper'

describe 'Flashes' do
  context 'when impersonating another user role' do
    before do
      FactoryGirl.build(:admin)
      sign_in_as_user(@admin)
      visit root_path
    end

    it 'has a link to the documentation' do
      click_on('Patron')
      expect(page).to have_link('here', href: 'https://yalestc.github.io/reservations/')
    end

    it 'has a link to where you revert the view' do
      click_on('Patron')
      expect(page).to have_link('below', href: '#view_as')
    end
  end
end
