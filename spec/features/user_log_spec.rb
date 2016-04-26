require 'spec_helper'

feature 'User log', type: :feature do
  scenario 'records user edits' do
    sign_in_as_user @admin
    visit edit_user_path(@user)
    fill_in 'user_nickname', with: 'Funnyman'
    click_button 'Update User'
    visit log_user_path(@user)

    expect(page).to have_content 'to Funnyman'

    sign_out
  end

  scenario 'records role change' do
    sign_in_as_user @admin
    visit edit_user_path(@user)
    select 'checkout', from: 'user_role'
    click_button 'Update User'
    visit log_user_path(@user)

    expect(page).to have_content 'to Checkout Person'

    sign_out
  end
end
