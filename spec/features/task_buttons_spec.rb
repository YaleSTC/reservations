# frozen_string_literal: true

require 'spec_helper'

describe 'Rake task buttons', type: :feature do
  before do
    sign_in_as_user FactoryGirl.create(:superuser)
    # The following is necessary to "undo" a stub / mock called for all feature
    # specs that was designed to avoid weird issues with persistent AppConfig
    # settings across tests. In principle, we shouldn't really be using mock
    # data in feature specs, but rather than try to fix all specs we're going to
    # just make sure that for these specs we get an actual AppConfig object so
    # that the form renders correctly. For reference, the stub occurs in
    # spec/support/app_config_helpers.rb, called in
    # spec/support/feature_helpers.rb.
    FactoryGirl.create(:app_config).tap do |ac|
      allow(AppConfig).to receive(:first).and_return(ac)
    end
  end

  it 'works for daily tasks' do
    visit root_path
    click_on 'Settings'
    click_on 'Run Daily Tasks'
    expect(page).to have_css('.alert-success',
                             text: /Daily tasks queued and running/)
  end

  it 'works for hourly tasks' do
    visit root_path
    click_on 'Settings'
    click_on 'Run Hourly Tasks'
    expect(page).to have_css('.alert-success',
                             text: /Hourly tasks queued and running/)
  end
end
