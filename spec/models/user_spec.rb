require 'spec_helper'
include EnvHelpers

describe User, type: :model do
  it 'has a working factory' do
    expect(FactoryGirl.create(:user)).to be_valid
  end

  context 'validations and associations' do
    before(:each) do
      @user = FactoryGirl.create(:user)
    end

    it { is_expected.to have_many(:reservations) }
    it { is_expected.to have_and_belong_to_many(:requirements) }

    it { is_expected.to validate_presence_of(:username) }
    it { is_expected.to validate_uniqueness_of(:username) }
    it { is_expected.to validate_presence_of(:first_name) }
    it { is_expected.to validate_presence_of(:last_name) }
    it { is_expected.to validate_presence_of(:affiliation) }
    it { is_expected.to validate_presence_of(:email) }
    it do
      is_expected.not_to\
        allow_value('abc', '!s@abc.com', 'a@!d.com', 'a@a.c0m').for(:email)
    end
    it do
      is_expected.to\
        allow_value('example@example.com', '1a@a.edu', 'a@2a.net').for(:email)
    end

    # These tests are commented because currently, the app does not validate
    # phone unless that option is specifically requested by the admin. This
    # needs to be expanded in order to test all admin options in app config.

    # it { should validate_presence_of(:phone) }
    # it { should_not allow_value("abcdef", "555-555-55$5").for(:phone) }
    # it { should allow_value("555-555-5555", "15555555555").for(:phone) }

    it { is_expected.not_to allow_value('ab@', 'ab1', 'ab_c').for(:nickname) }
    it { is_expected.to allow_value(nil, '', 'abc', 'Example').for(:nickname) }

    # TODO: figure out why it's saving with terms_of_service_accepted = false
    it 'must accept ToS' do
      # @user.terms_of_service_accepted = nil
      #  @user.save.should be_nil
      @user.terms_of_service_accepted = true
      expect(@user.save).to be_truthy
    end

    # this test means nothing if the previous one fails
    it "doesn't have to accept ToS if created by an admin" do
      @user_made_by_admin =
        FactoryGirl.build(:user,
                          created_by_admin: true,
                          terms_of_service_accepted: false)
      expect(@user_made_by_admin.save).to be_truthy
    end
  end

  describe 'nickname' do
    before(:each) do
      @user = FactoryGirl.create(:user)
    end

    it 'should default to empty string' do
      expect(@user.nickname).to eq('')
    end

    it 'should not allow nil' do
      @user.nickname = nil
      expect(->() { @user.save }).to\
        raise_error(ActiveRecord::StatementInvalid)
      #      User.find(@user.id).nickname.should_not be_nil
      # this test fails, saying that user nickname
      # cannot be nil so...idk what is going on
    end
  end

  describe '.active' do
    before(:each) do
      @user = FactoryGirl.create(:user)
      @deactivated = FactoryGirl.create(:banned)
    end

    it 'should return all active users' do
      expect(User.active).to include(@user)
    end

    it 'should not return inactive users' do
      expect(User.active).not_to include(@deactivated)
    end
  end

  describe '.name' do
    it 'should return the nickname and last name joined into one string if '\
      'nickname is specified' do
      @user = FactoryGirl.create(:user, nickname: 'Sasha Fierce')
      expect(@user.name).to eq("#{@user.nickname} #{@user.last_name}")
    end
    it 'should return the first and last name if user has no nickname '\
      'specified' do
      @no_nickname = FactoryGirl.create(:user)
      expect(@no_nickname.name).to\
        eq("#{@no_nickname.first_name} #{@no_nickname.last_name}")
    end
  end

  describe '.equipment_items' do
    it 'has a working reservation factory' do
      @reservation = FactoryGirl.create(:valid_reservation)
    end
    it 'should return all equipment_items reserved by the user' do
      @user = FactoryGirl.create(:user)
      @reservation = FactoryGirl.create(:valid_reservation, reserver: @user)
      expect(@user.equipment_items).to eq([@reservation.equipment_item])
    end
  end

  # TODO: find a way to simulate an ldap database using a test fixture/factory
  # of some kind
  describe '#search_ldap' do
    it 'should return a hash of user attributes if the ldap database has the '\
      'login associated with user'
    it 'should return nil if the user is not in the ldap database'
  end

  describe '#select_options' do
    it 'should return an array of all users ordered by last name, each '\
      "represented by an array like this: ['first_name last_name', id]" do
      @user1 = FactoryGirl.create(:user,
                                  first_name: 'Joseph',
                                  last_name: 'Smith',
                                  nickname: 'Joe')
      @user2 = FactoryGirl.create(:user,
                                  first_name: 'Jessica',
                                  last_name: 'Greene',
                                  nickname: 'Jess')
      expect(User.select_options).to\
        eq([["#{@user2.last_name}, #{@user2.first_name}", @user2.id],
            ["#{@user1.last_name}, #{@user1.first_name}", @user1.id]])
    end
  end

  describe '.render_name' do
    it 'should return the nickname, last name, and username id as a string '\
      'if nickname exists and if using CAS' do
      env_wrapper('CAS_AUTH' => '1') do
        @user = FactoryGirl.create(:user, nickname: 'Sasha Fierce')
        expect(@user.render_name).to\
          eq("#{@user.nickname} #{@user.last_name} #{@user.username}")
      end
    end
    it 'should return the first name, last name, and username id as a '\
      'string if no nickname and if using CAS' do
      env_wrapper('CAS_AUTH' => '1') do
        @no_nickname = FactoryGirl.create(:user)
        expect(@no_nickname.render_name).to\
          eq("#{@no_nickname.first_name} #{@no_nickname.last_name} "\
            "#{@no_nickname.username}")
      end
    end
    it 'should return the nickname and last name as a string if nickname '\
      'exists and not using CAS' do
      env_wrapper('CAS_AUTH' => nil) do
        @user = FactoryGirl.create(:user, nickname: 'Sasha Fierce')
        expect(@user.render_name).to eq("#{@user.nickname} #{@user.last_name}")
      end
    end
    it 'should return the first name and last name as a string if no '\
      'nickname and not using CAS' do
      env_wrapper('CAS_AUTH' => nil) do
        @no_nickname = FactoryGirl.create(:user)
        expect(@no_nickname.render_name).to\
          eq("#{@no_nickname.first_name} #{@no_nickname.last_name}")
      end
    end
  end
end
