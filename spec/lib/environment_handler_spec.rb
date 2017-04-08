# frozen_string_literal: true
require 'spec_helper'
include EnvironmentHandler

describe EnvironmentHandler do
  describe '.env?' do
    it 'returns false when variable not set' do
      allow(ENV).to receive(:[]).with('CAS_AUTH').and_return(nil)
      expect(env?('CAS_AUTH')).to be_falsey
    end
    it 'returns false when variable set to 0' do
      allow(ENV).to receive(:[]).with('CAS_AUTH').and_return('0')
      expect(env?('CAS_AUTH')).to be_falsey
    end
    it 'returns false when variable set to false' do
      allow(ENV).to receive(:[]).with('CAS_AUTH').and_return('false')
      expect(env?('CAS_AUTH')).to be_falsey
    end
    it 'returns false when variable set to empty string' do
      allow(ENV).to receive(:[]).with('CAS_AUTH').and_return('')
      expect(env?('CAS_AUTH')).to be_falsey
    end
    it 'returns true when variable set to anything except 0 or false' do
      allow(ENV).to receive(:[]).with('CAS_AUTH').and_return('true')
      expect(env?('CAS_AUTH')).to be_truthy
    end
  end
end
