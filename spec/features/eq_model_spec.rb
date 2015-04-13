require 'spec_helper'

describe 'Equipment Model views', type: :feature do
  before(:each) do
    app_setup
    @eq_model = EquipmentModel.first
  end

  context 'show view' do
    context 'pending reservations' do
      before(:each) do
        4.times do
          FactoryGirl.create :equipment_item, equipment_model: @eq_model
        end
        FactoryGirl.build(:checked_in_reservation,
                          equipment_model: @eq_model).save(validate: false)

        @today_res =
          FactoryGirl.create :valid_reservation,
                             equipment_model: @eq_model,
                             start_date: Time.zone.today
        @pending_res_1 =
          FactoryGirl.create :valid_reservation,
                             equipment_model: @eq_model,
                             start_date: Time.zone.today + 1.day,
                             due_date: Time.zone.today + 3.days
        @pending_res_2 =
          FactoryGirl.create :valid_reservation,
                             equipment_model: @eq_model,
                             start_date: Time.zone.today + 1.day,
                             due_date: Time.zone.today + 3.days
        @far_future_res =
          FactoryGirl.create :valid_reservation,
                             equipment_model: @eq_model,
                             start_date: Time.zone.today + 9.day,
                             due_date: Time.zone.today + 10.days
      end

      shared_examples 'can see pending reservations' do
        it 'displays the correct counts and links' do
          num_divs =
            page.all(:css, 'section#pending_reservations .giant-numbers div')
          expect(num_divs[0].text).to eq('1')
          expect(num_divs[1].text).to eq('2')
          expect(page).to have_link "#{@today_res.id}",
                                    href: reservation_path(@today_res)
          expect(page).to have_link "#{@pending_res_1.id}",
                                    href: reservation_path(@pending_res_1)
          expect(page).to have_link "#{@pending_res_2.id}",
                                    href: reservation_path(@pending_res_2)
          expect(page).not_to have_link "#{@far_future_res.id}",
                                        href: reservation_path(@far_future_res)
        end
      end

      shared_examples 'cannot see pending reservations' do
        it 'does not display the section' do
          expect(page).not_to have_content 'section#pending_reservations'
        end
      end

      context 'as superuser' do
        before do
          # sign_in_as_user @superuser
          @superuser = FactoryGirl.create :user, role: 'superuser',
                                                 view_mode: 'superuser'
          visit root_path
          click_link 'Sign In', match: :first
          fill_in 'Email', with: @superuser.email
          fill_in 'Password', with: 'passw0rd'
          click_button 'Sign in'
          visit equipment_model_path(@eq_model)
        end
        after { click_link 'Log Out' } # sign_out }

        it_behaves_like 'can see pending reservations'
      end

      context 'as admin' do
        before do
          # sign_in_as_user @admin
          visit root_path
          click_link 'Sign In', match: :first
          fill_in 'Email', with: @admin.email
          fill_in 'Password', with: 'passw0rd'
          click_button 'Sign in'
          visit equipment_model_path(@eq_model)
        end
        after { click_link 'Log Out' } # sign_out }

        it_behaves_like 'can see pending reservations'
      end

      context 'as checkout person' do
        before do
          # sign_in_as_user @superuser
          @checkout_person = FactoryGirl.create :checkout_person
          visit root_path
          click_link 'Sign In', match: :first
          fill_in 'Email', with: @checkout_person.email
          fill_in 'Password', with: 'passw0rd'
          click_button 'Sign in'
          visit equipment_model_path(@eq_model)
        end
        after { click_link 'Log Out' } # sign_out }

        it_behaves_like 'cannot see pending reservations'
      end

      context 'as patron' do
        before do
          # sign_in_as_user @user
          visit root_path
          click_link 'Sign In', match: :first
          fill_in 'Email', with: @user.email
          fill_in 'Password', with: 'passw0rd'
          click_button 'Sign in'
          visit equipment_model_path(@eq_model)
        end
        after { click_link 'Log Out' } # sign_out }

        it_behaves_like 'cannot see pending reservations'
      end

      context 'as guest' do
        before { visit equipment_model_path(@eq_model) }

        it_behaves_like 'cannot see pending reservations'
      end
    end
  end
end
