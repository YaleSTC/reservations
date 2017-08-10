# frozen_string_literal: true

require 'spec_helper'

describe Requirement, type: :model do
  context 'Validations' do
    before(:each) do
      @requirement = FactoryGirl.build(:requirement)
    end
    it 'has a working factory' do
      expect(@requirement.save).to be_truthy
    end

    it { is_expected.to validate_presence_of(:contact_name) }
    it { is_expected.to validate_presence_of(:description) }
    it { is_expected.to validate_presence_of(:contact_info) }
    it { is_expected.to have_and_belong_to_many(:equipment_models) }
    it { is_expected.to have_and_belong_to_many(:users) }
  end
end
