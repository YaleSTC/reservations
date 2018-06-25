# frozen_string_literal: true

require 'spec_helper'

describe 'Reservation receipts' do
  before do
    # Necessary to override our mocked AppConfig
    allow(AppConfig.first).to receive(:disable_user_emails).and_return(false)
    sign_in_as_user @admin
  end

  context 'when checked out' do
    let(:reservation) { FactoryGirl.create(:checked_out_reservation) }

    it 'sends check out receipts' do
      visit reservation_path(reservation)
      click_on 'Email checkout receipt'
      expect(page).to have_css('.alert-success',
                               text: /Successfully delivered receipt email./)
    end

    it 'sends the right e-mail' do
      visit reservation_path(reservation)
      click_on 'Email checkout receipt'
      email = ActionMailer::Base.deliveries.last
      expect(email.subject).to match(/.+Checked Out$/)
    end
  end

  context 'when checked in' do
    let(:reservation) { FactoryGirl.create(:checked_in_reservation) }

    it 'sends check in receipts' do
      visit reservation_path(reservation)
      click_on 'Email return receipt'
      expect(page).to have_css('.alert-success',
                               text: /Successfully delivered receipt email./)
    end

    it 'sends the right e-mail' do
      visit reservation_path(reservation)
      click_on 'Email return receipt'
      email = ActionMailer::Base.deliveries.last
      expect(email.subject).to match(/.+Returned$/)
    end
  end
end
