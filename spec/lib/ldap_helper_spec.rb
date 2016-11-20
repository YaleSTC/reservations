# frozen_string_literal: true
require 'spec_helper'

describe LDAPHelper do
  def mock_ldap(user_hash)
    instance_spy(Net::LDAP, search: user_hash)
  end

  context 'LDAP enabled' do
    around(:example) do |example|
      env_wrapper('CAS_AUTH' => 1, 'USE_LDAP' => 1) { example.run }
    end

    describe '#search' do
      xit 'returns a properly formatted hash'
    end
  end
end
