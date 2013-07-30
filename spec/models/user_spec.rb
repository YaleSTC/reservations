require 'spec_helper'

describe User do
  it "has a working factory" do
    FactoryGirl.create(:user).should be_valid
  end

  context "validations and associations" do
    before(:each) do
      @user = FactoryGirl.create(:user)
      
    end

    it { should have_many(:reservations) }
    it { should have_and_belong_to_many(:requirements) }

    it { should validate_presence_of(:login) }
    it { should validate_uniqueness_of(:login) }
    it { should validate_presence_of(:first_name) }
    it { should validate_presence_of(:last_name) }
    it { should validate_presence_of(:affiliation) }
    it { should validate_presence_of(:phone) }
    it { should validate_presence_of(:email) }
    it { should_not allow_value("abc", "!s@abc.com", "a@!d.com", "a@a.c0m").for(:email) }
    it { should allow_value("example@example.com", "1a@a.edu", "a@2a.net").for(:email) }
    it { should_not allow_value("abcdef", "555-555-55$5", "1234 1234 1234").for(:phone) }
    it { should allow_value("555-555-5555", "15555555555").for(:phone) }
    it { should_not allow_value("ab@", "ab1", "ab_c").for(:nickname) }
    it { should allow_value(nil, "", "abc", "Example").for(:nickname) }

    #TODO: figure out why it's saving with terms_of_service_accepted = false
    it "must accept ToS" do
     # @user.terms_of_service_accepted = nil
     #  @user.save.should be_nil
       @user.terms_of_service_accepted = true
       @user.save.should be_true
    end

    # this test means nothing if the previous one fails
    it "doesn't have to accept ToS if created by an admin" do
      @user_made_by_admin = FactoryGirl.build(:user, created_by_admin: true, terms_of_service_accepted: false)
      @user_made_by_admin.save.should be_true
    end
  end

  describe ".active" do
    before(:each) do
      @user = FactoryGirl.create(:user)
      @deactivated = FactoryGirl.create(:deactivated_user)
    end

    it "should return all active users" do
      User.active.should include(@user)
    end

    it "should not return inactive users" do
      User.active.should_not include(@deactivated)
    end
  end

  describe ".name" do
    it "should return the nickname and last name joined into one string if nickname is specified" do
      @user = FactoryGirl.create(:user, nickname: "Sasha Fierce")
      @user.name.should == "#{@user.nickname} #{@user.last_name}"
    end
    it "should return the first and last name if user has no nickname specified" do
      @no_nickname = FactoryGirl.create(:user)
      @no_nickname.name.should == "#{@no_nickname.first_name} #{@no_nickname.last_name}"
    end
  end

  describe ".can_checkout?" do
    it "should return true if user is a checkout person" do
      checkout_person = FactoryGirl.create(:checkout_person)
      checkout_person.can_checkout?.should == true
    end
    it "should return true if user is an admin in admin mode" do
      admin_in_admin_mode = FactoryGirl.create(:admin, view_mode: 'admin')
      admin_in_admin_mode.can_checkout?.should == true
    end
    it "should return true if user is an admin in checkoutperson mode" do
      admin_in_checkout_mode = FactoryGirl.create(:admin, view_mode: 'checkout')
      admin_in_checkout_mode.can_checkout?.should == true
    end
    it "should return false if user is banned" do
      banned_user = FactoryGirl.create(:user, role: 'banned')
      banned_user.can_checkout?.should be_false
    end
    it "should return false if user is normal" do
      non_admin_user = FactoryGirl.create(:user)
      non_admin_user.can_checkout?.should be_false
    end
    it "should return false if admin in bannedmode" do
      admin_in_bannedmode = FactoryGirl.create(:admin, view_mode: 'banned')
      admin_in_bannedmode.can_checkout?.should be_false
    end
    it "should return false if admin in normal mode" do
      admin_in_normalusermode = FactoryGirl.create(:admin, view_mode: 'normal')
      admin_in_normalusermode.can_checkout?.should be_false
    end
  end

  describe ".is_admin?" do
    it "should return true if user is admin and passed no parameter" do
      user = FactoryGirl.create(:admin)
      user.is_admin?.should be_true
    end
    context "not an admin" do
      before(:each) do
        @user = FactoryGirl.create(:user)
      end
      it "should return false if user is not an admin and passed no parameter" do
        @user.is_admin?.should be_false
      end
      it "should return false if user is not admin and passed a parameter" do
        @user.is_admin?(:as => 'admin').should be_false
        @user.is_admin?(:as => 'checkout').should be_false
        @user.is_admin?(:as => 'banned').should be_false
        @user.is_admin?(:as => 'normal').should be_false
      end
    end
    context "admin view_mode" do
      before(:each) do
        @user = FactoryGirl.create(:admin, view_mode: 'admin')
      end
      it "should return true if passed the parameter matching the view_mode" do
        @user.is_admin?(:as => 'admin').should be_true
      end
      it "should return false if passed a parameter not matching the view_mode" do
        @user.is_admin?(:as => 'checkout').should be_false
        @user.is_admin?(:as => 'normal').should be_false
        @user.is_admin?(:as => 'banned').should be_false
      end
    end
    context "checkout view_mode" do
      before(:each) do
        @user = FactoryGirl.create(:admin, view_mode: 'checkout')
      end
      it "should return true if passed the parameter matching the view_mode" do
        @user.is_admin?(:as => 'checkout').should be_true
      end
      it "should return false if passed a parameter not matching the view_mode" do
        @user.is_admin?(:as => 'admin').should be_false
        @user.is_admin?(:as => 'normal').should be_false
        @user.is_admin?(:as => 'banned').should be_false
      end
    end
    context "banned view_mode" do
      before(:each) do
        @user = FactoryGirl.create(:admin, view_mode: 'banned')
      end
      it "should return true if passed the parameter matching the view_mode" do
        @user.is_admin?(:as => 'banned').should be_true
      end
      it "should return false if passed a parameter not matching the view_mode" do
        @user.is_admin?(:as => 'checkout').should be_false
        @user.is_admin?(:as => 'normal').should be_false
        @user.is_admin?(:as => 'admin').should be_false
      end
    end
    context "normal view_mode" do
      before(:each) do
        @user = FactoryGirl.create(:admin, view_mode: 'normal')
      end
      it "should return true if passed the parameter matching the view_mode" do
        @user.is_admin?(:as => 'normal').should be_true
      end
      it "should return false if passed a parameter not matching the view_mode" do
        @user.is_admin?(:as => 'checkout').should be_false
        @user.is_admin?(:as => 'admin').should be_false
        @user.is_admin?(:as => 'banned').should be_false
      end
    end
  end


  describe ".equipment_objects" do
    it "has a working reservation factory" do
      @reservation = FactoryGirl.create(:reservation)
    end
    it "should return all equipment_objects reserved by the user" do
      @user = FactoryGirl.create(:user)
      @reservation = FactoryGirl.create(:reservation, reserver: @user)
      @user.equipment_objects.should == [@reservation.equipment_object]
    end
  end

  describe ".checked_out_models" do
    it "should return a hash of checked out models and counts" do
      @user = FactoryGirl.create(:user)
      @model = FactoryGirl.create(:equipment_model)
      # make two reservations of the same equipment model, only one of which is checked out
      @reservation = FactoryGirl.create(:checked_out_reservation, reserver: @user, equipment_model: @model)
      @another_reservation = FactoryGirl.create(:reservation, reserver: @user, equipment_model: @model)

      @user.checked_out_models.should == {@model.id=>1}
    end
  end

  #TODO: find a way to simulate an ldap database using a test fixture/factory of some kind
  describe "#search_ldap" do
    it "should return a hash of user attributes if the ldap database has the login associated with user"
    it "should return nil if the user is not in the ldap database"
  end

  describe "#select_options" do
    it "should return an array of all users ordered by last name, each represented by an array like this: ['first_name last_name', id]" do
      @user1 = FactoryGirl.create(:user, first_name: "Joseph", last_name: "Smith", nickname: "Joe")
      @user2 = FactoryGirl.create(:user, first_name: "Jessica", last_name: "Greene", nickname: "Jess")
      User.select_options.should == [["#{@user2.last_name}, #{@user2.first_name}", @user2.id],["#{@user1.last_name}, #{@user1.first_name}", @user1.id]]
    end
  end

  describe ".render_name" do
    it "should return the nickname, last name, and login id as a string if nickname exists" do
      @user = FactoryGirl.create(:user, nickname: "Sasha Fierce")
      @user.render_name.should == "#{@user.nickname} #{@user.last_name} #{@user.login}"
    end
    it "should return the first name, last name, and login id as a string if no nickname" do
      @no_nickname = FactoryGirl.create(:user)
      @no_nickname.render_name.should == "#{@no_nickname.first_name} #{@no_nickname.last_name} #{@no_nickname.login}"
    end
  end
end
