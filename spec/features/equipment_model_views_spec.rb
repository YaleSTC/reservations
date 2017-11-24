# frozen_string_literal: true

require 'spec_helper'

describe 'Equipment model views' do
  subject { page }

  context 'index view' do
    shared_examples 'can view detailed table' do
      it { should have_selector 'th', text: 'Available' }
    end

    shared_examples 'can view full and detailed table' do
      it_behaves_like 'can view detailed table'
      it { expect(page).to have_link 'Edit' }
    end

    shared_examples 'displays appropriate information' do
      it { is_expected.to have_content('Equipment Models') }
      it { is_expected.to have_content(@eq_model.name) }
    end

    context 'check for super user' do
      before do
        sign_in_as_user(@superuser)
        visit equipment_models_path
      end
      after { sign_out }
      it_behaves_like 'can view full and detailed table'
      it_behaves_like 'displays appropriate information'
    end

    context 'check for admin' do
      before do
        sign_in_as_user(@admin)
        visit equipment_models_path
      end
      after { sign_out }
      it_behaves_like 'can view full and detailed table'
      it_behaves_like 'displays appropriate information'
    end

    context 'check for patron' do
      before do
        sign_in_as_user(@user)
        visit equipment_models_path
      end
      after { sign_out }
      it_behaves_like 'can view detailed table'
      it_behaves_like 'displays appropriate information'
    end

    context 'check for check out person' do
      before do
        sign_in_as_user(@checkout_person)
        visit equipment_models_path
      end
      after { sign_out }
      it_behaves_like 'can view detailed table'
      it_behaves_like 'displays appropriate information'
    end

    context 'check for guest' do
      before { visit equipment_models_path }
      it { should_not have_selector 'th', text: 'Available' }
      it_behaves_like 'displays appropriate information'
    end

    context 'check for banned user' do
      before do
        sign_in_as_user(@banned)
        visit equipment_models_path
      end
      after { sign_out }
      it { should_not have_selector 'th', text: 'Available' }
      it { is_expected.not_to have_content('Equipment Models') }
    end
  end
end
