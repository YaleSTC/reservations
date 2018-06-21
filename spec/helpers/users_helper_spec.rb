# frozen_string_literal: true

require 'spec_helper'

RSpec.describe UsersHelper, type: :helper do
  describe '.tos_attestation' do
    let(:user1) { FactoryGirl.build_stubbed :user }
    let(:user2) { FactoryGirl.build_stubbed :user }

    it 'returns "I accept" when the user is acting on their own behalf' do
      result = helper.tos_attestation(current_user: user1, user: user1)
      expect(result).to eq('I accept')
    end

    it "returns 'User accepts' when the user is acting on another's behalf" do
      result = helper.tos_attestation(current_user: user1, user: user2)
      expect(result).to eq('User accepts')
    end

    it 'returns "I accept" when the current user is not present' do
      result = helper.tos_attestation(current_user: nil, user: user1)
      expect(result).to eq('I accept')
    end
  end

  describe '.user_viewing_other_user?' do
    let(:user1) { FactoryGirl.build_stubbed :user }
    let(:user2) { FactoryGirl.build_stubbed :user }

    it 'returns true when a user is signed in and viewing another user' do
      result =
        helper.user_viewing_other_user?(current_user: user1, user: user2)
      expect(result).to be_truthy
    end

    it 'returns false when a user is signed in and viewing themselves' do
      result =
        helper.user_viewing_other_user?(current_user: user1, user: user1)
      expect(result).to be_falsey
    end

    it 'returns false when a user is not signed in' do
      result =
        helper.user_viewing_other_user?(current_user: nil, user: user1)
      expect(result).to be_falsey
    end
  end
end
