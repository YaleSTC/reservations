require 'spec_helper'

describe Message, type: :model do
  context 'validations' do
    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_presence_of(:email) }
    it { is_expected.to validate_presence_of(:subject) }
    it { is_expected.to validate_presence_of(:body) }
    it { is_expected.not_to allow_value('abc', '!s@abc.com', 'a@!d.com', 'a@a.c0m').for(:email) }
    it { is_expected.to allow_value('example@example.com', '1a@a.edu', 'a@2a.net').for(:email) }

    # this test currently fails but I'm not sure why
    # also, why would we want to be able to leave email blank?
    # it "should skip email format validation if input is nil or an empty string" do
    #  @message = FactoryGirl.build(:message, email: "")
    #  @message.should be_valid
    # end
  end
  describe '.persisted?' do
    it 'should always return false' do
      @message = FactoryGirl.build(:message)
      expect(@message.persisted?).to be_falsey
    end
  end
end
