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

      context 'visiting own profile edit page' do
        before do
          visit '/users/' + @user.id.to_s
          click_link 'Edit Information'
        end

        it 'shows the correct fields' do
          expect(page).to have_field('Password')
          expect(page).to have_field('Password confirmation')
          expect(page).to have_field('Current password')
          expect(page).not_to have_field('Username')
        end

        context 'updating profile' do
          before { fill_in 'First name', with: 'Senor' }

          it 'updates with valid password' do
            fill_in 'Current password', with: 'passw0rd'
            click_button 'Update User'

            expect(page).to have_content('Senor')
            expect(page.find('.alert')).to have_content('Successfully updated user.')
          end

          it 'does not update with invalid password' do
            fill_in 'Current password', with: 'wrongpassword'
            click_button 'Update User'

            expect(page).to have_content('Edit User')
            expect(page).to have_content('is invalid')
          end

          it 'does not update with blank password' do
            click_button 'Update User'

            expect(page).to have_content('Edit User')
            expect(page).to have_content('can\'t be blank')
          end

          context 'changing password' do
            before do
              fill_in 'Password', with: 'newpassword'
              fill_in 'Current password', with: 'passw0rd'
            end

            it 'updates with valid confirmation' do
              fill_in 'Password confirmation', with: 'newpassword'
              click_button 'Update User'

              expect(page).to have_content('Senor')
              expect(page.find('.alert')).to have_content('Successfully updated user.')
            end

            it 'does not update with invalid confirmation' do
              fill_in 'Password confirmation', with: 'wrongpassword'
              click_button 'Update User'

              expect(page).to have_content('Edit User')
              expect(page).to have_content('doesn\'t match Password')
            end
          end
        end
      end

      context 'trying to edit a different user' do
        before do
          visit '/users/' + @admin.id.to_s
        end

        it 'redirects to home page' do
          expect(page).to have_content('Catalog')
          expect(page.find('.alert')).to have_content('Sorry, that action or page is restricted.')
        end
      end
    end

    context 'as admin user' do
      before { login_as(@admin, scope: :user) }

      context 'visiting own profile edit page' do
        before do
          visit '/users/' + @admin.id.to_s
          click_link 'Edit Information'
        end

        it 'shows the correct fields' do
          expect(page).to have_field('Password')
          expect(page).to have_field('Password confirmation')
          expect(page).to have_field('Current password')
          expect(page).not_to have_field('Username')
        end

        context 'updating profile' do
          before { fill_in 'First name', with: 'Senor' }

          it 'updates with valid password' do
            fill_in 'Current password', with: 'passw0rd'
            click_button 'Update User'

            expect(page).to have_content('Senor')
            expect(page.find('.alert')).to have_content('Successfully updated user.')
          end

          it 'does not update with invalid password' do
            fill_in 'Current password', with: 'wrongpassword'
            click_button 'Update User'

            expect(page).to have_content('Edit User')
            expect(page).to have_content('is invalid')
          end

          it 'does not update with blank password' do
            click_button 'Update User'

            expect(page).to have_content('Edit User')
            expect(page).to have_content('can\'t be blank')
          end

          context 'changing password' do
            before do
              fill_in 'Password', with: 'newpassword'
              fill_in 'Current password', with: 'passw0rd'
            end

            it 'updates with valid confirmation' do
              fill_in 'Password confirmation', with: 'newpassword'
              click_button 'Update User'

              expect(page).to have_content('Senor')
              expect(page.find('.alert')).to have_content('Successfully updated user.')
            end

            it 'does not update with invalid confirmation' do
              fill_in 'Password confirmation', with: 'wrongpassword'
              click_button 'Update User'

              expect(page).to have_content('Edit User')
              expect(page).to have_content('doesn\'t match Password')
            end
          end
        end
      end

      context 'trying to edit a different user' do
        before do
          visit '/users/' + @user.id.to_s
          click_link 'Edit Information'
        end

        it 'shows the correct fields' do
          expect(page).not_to have_field('Password')
          expect(page).not_to have_field('Password confirmation')
          expect(page).not_to have_field('Current password')
          expect(page).not_to have_field('Username')
        end

        it 'can update profile' do
          fill_in 'First name', with: 'Senor'
          click_button 'Update User'

          expect(page).to have_content('Senor')
          expect(page.find('.alert')).to have_content('Successfully updated user.')
        end
      end
    end
  end

  context 'with CAS authentication' do
    around(:example) do |example|
      env_wrapper('CAS_AUTH' => '1') { example.run }
    end

    context 'as normal user' do
      before { login_as(@user, scope: :user) }

      context 'visiting own profile edit page' do
        before do
          visit '/users/' + @user.id.to_s
          click_link 'Edit Information'
        end

        it 'shows the correct fields' do
          expect(page).not_to have_field('Password')
          expect(page).not_to have_field('Password confirmation')
          expect(page).not_to have_field('Current password')
          expect(page).to have_field('Username')
        end

        it 'can update profile' do
          fill_in 'First name', with: 'Senor'
          click_button 'Update User'

          expect(page).to have_content('Senor')
          expect(page.find('.alert')).to have_content('Successfully updated user.')
        end
      end

      context 'trying to edit a different user' do
        before do
          visit '/users/' + @admin.id.to_s
        end

        it 'redirects to home page' do
          expect(page).to have_content('Catalog')
          expect(page.find('.alert')).to have_content('Sorry, that action or page is restricted.')
        end
      end
    end

    context 'as admin user' do
      before { login_as(@admin, scope: :user) }

      context 'visiting own profile edit page' do
        before do
          visit '/users/' + @admin.id.to_s
          click_link 'Edit Information'
        end

        it 'shows the correct fields' do
          expect(page).not_to have_field('Password')
          expect(page).not_to have_field('Password confirmation')
          expect(page).not_to have_field('Current password')
          expect(page).to have_field('Username')
        end

        it 'can update profile' do
          fill_in 'First name', with: 'Senor'
          click_button 'Update User'

          expect(page).to have_content('Senor')
          expect(page.find('.alert')).to have_content('Successfully updated user.')
        end
      end

      context 'trying to edit a different user' do
        before do
          visit '/users/' + @user.id.to_s
          click_link 'Edit Information'
        end

        it 'shows the correct fields' do
          expect(page).not_to have_field('Password')
          expect(page).not_to have_field('Password confirmation')
          expect(page).not_to have_field('Current password')
          expect(page).to have_field('Username')
        end

        it 'can update profile' do
          fill_in 'First name', with: 'Senor'
          click_button 'Update User'

          expect(page).to have_content('Senor')
          expect(page.find('.alert')).to have_content('Successfully updated user.')
        end
      end
    end
  end
end
