require 'spec_helper'

feature 'User log', type: :feature, versioning: true do
  scenario 'records user edits' do
    sign_in_as_user @admin
    visit edit_user_path(@user)
    fill_in 'user_nickname', with: 'Funnyman'
    click_button 'Update User'
    visit log_user_path(@user)

    # test for two versions (creation and update)
    expect(page).to have_css '[data-role=user-version]', count: 2

    sign_out
  end

  scenario 'records role change' do
    sign_in_as_user @admin
    visit edit_user_path(@user)
    select 'checkout', from: 'user_role'
    click_button 'Update User'
    visit log_user_path(@user)

    # test for two versions (creation and update)
    expect(page).to have_css '[data-role=user-version]', count: 2

    sign_out
  end

  scenario 'does not record password changes' do
    sign_in_as_user @user
    visit edit_user_path(@user)
    fill_in 'user_password', with: 'passw0rd2'
    fill_in 'user_password_confirmation', with: 'passw0rd2'
    fill_in 'user_current_password', with: 'passw0rd'
    click_button 'Update User'
    sign_out
    sign_in_as_user @admin
    visit log_user_path(@user)

    expect(page).to have_css '[data-role=user-version]', count: 1

    sign_out
  end
end
