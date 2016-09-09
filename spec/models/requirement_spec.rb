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

  describe '#list_requirement_admins' do
    before(:each) do
      @requirement = FactoryGirl.create(:requirement)
      @another_requirement = FactoryGirl.create(:another_requirement)
      @equipment_model =
        FactoryGirl.create(:equipment_model,
                           requirements: [@requirement, @another_requirement])
      @user_with_unmet_requirement = FactoryGirl.create(:user)
      @user_that_meets_some_requirements =
        FactoryGirl.create(:user, requirements: [@requirement])
    end

    it 'should return a list of admins and contact info if no requirements '\
      'have been met.' do
      req_message = 'This model requires proper training before it can be '\
        "reserved. Please contact #{@requirement.contact_name} and "\
        "#{@another_requirement.contact_name} respectively at "\
        "#{@requirement.contact_info} and "\
        "#{@another_requirement.contact_info} about becoming certified."
      expect(Requirement.list_requirement_admins(@user_with_unmet_requirement,
                                                 @equipment_model)
            .include?(req_message)).to be_truthy
    end

    it 'should return a list of met requirements, followed by unmet '\
      'requirements if they exists' do
      req_message = 'You have already met the requirements to check out this '\
        "model set by #{@requirement.contact_name}. However, this model "\
        'requires additional training before it can be reserved. Please '\
        "contact #{@another_requirement.contact_name} at "\
        "#{@another_requirement.contact_info} about becoming certified."
      expect(Requirement
        .list_requirement_admins(@user_that_meets_some_requirements,
                                 @equipment_model)
        .include?(req_message)).to be_truthy
    end
  end
end
