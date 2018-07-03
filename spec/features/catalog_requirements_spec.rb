# frozen_string_literal: true

require 'spec_helper'

describe 'Catalog view', type: :feature do
  context 'with requirement' do
    it 'renders equipment with a requirement' do
      @eq_model.requirements << FactoryGirl.create(:requirement)
      sign_in_as_user @user
      visit root_path
      expect(page).to have_css('.equipment_title_link', text: @eq_model.name)
    end
  end
end
