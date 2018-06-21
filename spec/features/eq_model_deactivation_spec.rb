# frozen_string_literal: true

require 'spec_helper'

describe 'Equipment Model deactivation', type: :feature do
  let(:eq_model) { FactoryGirl.create(:equipment_model) }

  before do
    FactoryGirl.create(:equipment_item, equipment_model: eq_model)
  end

  after { sign_out }

  shared_examples 'success' do
    it 'can deactivate and reactivate', js: true do
      visit equipment_model_path(eq_model)
      click_link 'Deactivate',
                 href: "/equipment_models/#{eq_model.id}/deactivate"
      click_link 'Activate', href: "/equipment_models/#{eq_model.id}/activate"
      expect(page).to have_css('.alert.alert-success',
                               text: /Successfully reactivated/)
    end
  end

  shared_examples 'unauthorized' do
    it 'cannot deactivate' do
      visit equipment_model_path(eq_model)
      expect(page).not_to have_link 'Deactivate'
    end
  end

  context 'as superuser' do
    before { sign_in_as_user @superuser }

    it_behaves_like 'success'
  end

  context 'as admin' do
    before { sign_in_as_user @admin }

    it_behaves_like 'success'
  end

  context 'as checkout person' do
    before { sign_in_as_user @checkout_person }

    it_behaves_like 'unauthorized'
  end

  context 'as patron' do
    before { sign_in_as_user @user }

    it_behaves_like 'unauthorized'
  end

  context 'as guest' do
    it_behaves_like 'unauthorized'
  end
end
