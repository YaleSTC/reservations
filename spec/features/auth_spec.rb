require 'spec_helper'

shared_examples_for 'valid registration' do
  it { is_expected.to have_content 'Successfully created user.' }
  it { is_expected.to have_content 'John Smith' }
  it { is_expected.to have_link 'Log Out' }
end

shared_examples_for 'form error' do
  it { is_expected.to have_content('New User') }
  it { is_expected.to have_content("Please review the problems below:") }
end

describe 'Authentication' do
  subject { page }
  before(:each) do
    app_setup
  end

  describe 'using CAS' do
    # set the environment variable
    around(:example) do |example|
      env_wrapper('CAS_AUTH' => '1') { example.run }
    end

    # Not sure how to check new sign_in since we're not actually using the
    # Devise log in function so we don't go through the post-login method.
    # That said, we can stub session[:new_username] to test the functionality
    # of the UsersController#new method
    context 'where user does not exist' do
      before do
        @new_user = FactoryGirl.build(:user)
        inject_session new_username: @new_user.username
        visit 'users/new'
      end

      it 'should display the form properly' do
        expect(page).to have_field('user_username', with: @new_user.username)
        expect(page).not_to have_field('user_password')
      end
    end

    context 'where user does exist' do
      # not sure how to deal with testing logging in since it's using CAS
      pending 'should work properly'
    end
  end

  describe 'using password' do
    # set the environment variable
    around(:example) do |example|
      env_wrapper('CAS_AUTH' => nil) { example.run }
    end

    context 'with new user' do
      context 'can register' do
        before do
          visit '/'
          click_link 'Sign In', match: :first
          click_link 'Register'
        end

        it 'displays registration form' do
          expect(page).to have_field('user_password')
          expect(page).not_to have_field('user_username')
        end

        context 'with valid registration' do
          before do
            fill_in_registration
            click_button 'Create User'
          end

          it_behaves_like 'valid registration'
        end

        context 'with invalid registration' do
          before do
            fill_in_registration
          end

          context 'with mismatched passwords' do
            before do
              fill_in 'user_password_confirmation', with: 'password'
              click_button 'Create User'
            end

            it_behaves_like 'form error'
          end

          context 'with missing passwords' do
            before do
              fill_in 'user_password', with: ''
              click_button 'Create User'
            end

            it_behaves_like 'form error'
          end

          context 'with short password' do
            before do
              fill_in 'user_password', with: '1234'
              fill_in 'user_password_confirmation', with: '1234'
              click_button 'Create User'
            end

            it_behaves_like 'form error'
          end
        end
      end
    end
  end
end

def fill_in_registration
  fill_in 'Email', with: 'example@example.com'
  fill_in 'user_password', with: 'passw0rd'
  fill_in 'user_password_confirmation', with: 'passw0rd'
  fill_in 'First name', with: 'John'
  fill_in 'Last name', with: 'Smith'
  fill_in 'Affiliation', with: 'Yale'
end