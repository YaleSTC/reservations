# frozen_string_literal: true

require 'spec_helper'

describe 'Import Users', type: :feature do
  before do
    sign_in_as_user(@admin)
    create(:user, username: 'BANME')
    create(:user, username: 'ME2')
  end

  it 'can bulk ban users given only usernames' do
    visit csv_import_page_url
    attach_users_to_ban_csv
    check 'overwrite'
    select 'Banned Users', from: 'user_type'
    click_on 'Import Users'
    expect(page).to have_content('Users successfully imported')
  end

  def attach_users_to_ban_csv
    file_path = Rails.root + 'spec/fixtures/users_to_ban.csv'
    attach_file('csv_upload', file_path)
  end
end
