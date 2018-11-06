# frozen_string_literal: true

require 'spec_helper'
include CsvImport

describe CsvImport do
  let(:parsed_csv) do
    [{ username: 'abc123', first_name: '',
       last_name: '', nickname: '',
       phone: '', email: '', affiliation: '' }]
  end

  context 'when CAS login is used' do
    context 'when only username is provided' do
      before do
        ENV['USE_PEOPLE_API'] = 'true'
        allow(User).to receive(:search).and_return(search_user_return)
      end

      it 'calls User.search' do
        described_class.import_users(parsed_csv, false, 'normal')
        expect(User).to have_received(:search).once
      end

      it 'populates the appropriate fields' do
        result = described_class
                 .import_users(parsed_csv, false, 'normal')[:success][0]
                 .attributes.to_h
        expect(result).to include(expected_user_update_hash)
      end
    end

    def search_user_return
      { cas_login: 'abc123', first_name: 'Max', last_name: 'Power',
        email: 'max.power@email.email', affiliation: 'STAFF',
        username: 'max.power@email.email' }
    end

    def expected_user_update_hash
      { 'username' => 'abc123', 'first_name' => 'Max', 'last_name' => 'Power',
        'nickname' => '', 'phone' => nil, 'email' => 'max.power@email.email',
        'affiliation' => 'STAFF', 'cas_login' => 'abc123', 'role' => 'normal' }
    end
  end
end
