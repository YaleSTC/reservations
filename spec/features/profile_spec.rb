require 'spec_helper'

describe 'User profile' do
  subject { page }
  before(:each) { app_setup }

  context 'with password authentication' do
    around(:example) do |example|
      env_wrapper('CAS_AUTH' => nil) { example.run }
    end

    context 'as normal user' do
      before { login_as(@user, scope: :user) }

      context 'visiting your own' do
        before do
          visit '/users/'+@user.id
          click_link 'Edit Information'
        end

        it 'shows the password fields' do
          expect(page).to have_field('Password')
          expect(page).to have_field('Password confirmation')
          expect(page).to have_field('Current password')
        end

        context 'with valid password' do
        end

        context 'with invalid password' do
        end
      end
    end
  end
end