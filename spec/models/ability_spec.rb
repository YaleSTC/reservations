require 'spec_helper'
require 'cancan/matchers'

describe Ability, type: :model do
  before(:each) do
    mock_app_config(enable_renewals: true)
  end

  shared_examples 'all users' do
    it { is_expected.to be_able_to(:hide, Announcement) }
  end

  shared_examples 'normal user' do
    it { is_expected.to be_able_to(:update, User, id: user.id) }
    it { is_expected.to be_able_to(:show, User, id: user.id) }

    it { is_expected.to be_able_to(:read, EquipmentModel) }
    it { is_expected.to be_able_to(:view_detailed, EquipmentModel) }

    it { is_expected.to be_able_to(:read, Reservation, reserver_id: user.id) }
    it { is_expected.to be_able_to(:create, Reservation, reserver_id: user.id) }
    it do
      expect(ability).to be_able_to(:destroy, Reservation, reserver_id: user.id,
                                    checked_out: nil)
    end
    it { is_expected.to be_able_to(:renew, Reservation, reserver_id: user.id) }
    it { is_expected.to be_able_to(:update_index_dates, Reservation) }
    it { is_expected.to be_able_to(:view_all_dates, Reservation) }

    it { is_expected.to be_able_to(:reload_catalog_cart, :all) }
    it { is_expected.to be_able_to(:update_cart, :all) }
  end

  context 'superuser' do
    subject(:ability) { Ability.new(UserMock.new(:superuser)) }
    it_behaves_like 'all users'
    it { is_expected.to be_able_to(:view_as, :superuser) }
    it { is_expected.to be_able_to(:change, :views) }
    it { is_expected.to be_able_to(:manage, :all) }
  end

  context 'admin' do
    subject(:ability) { Ability.new(UserMock.new(:admin)) }
    it_behaves_like 'all users'
    it { is_expected.to be_able_to(:change, :views) }
    it { is_expected.to be_able_to(:manage, :all) }
    it { is_expected.not_to be_able_to(:view_as, :superuser) }
    it { is_expected.not_to be_able_to(:appoint, :superuser) }
    it { is_expected.not_to be_able_to(:destroy, User, role: 'superuser') }
    it { is_expected.not_to be_able_to(:update, User, role: 'superuser') }
    it { is_expected.not_to be_able_to(:access, :rails_admin) }
  end

  context 'checkout person' do
    let!(:user) { UserMock.new(:checkout_person) }
    subject(:ability) { Ability.new(user) }
    it_behaves_like 'all users'
    it_behaves_like 'normal user'

    it { is_expected.to be_able_to(:manage, Reservation) }
    it { is_expected.not_to be_able_to(:archive, Reservation) }

    it { is_expected.to be_able_to(:read, User) }
    it { is_expected.to be_able_to(:update, User) }
    it { is_expected.to be_able_to(:find, User) }
    it { is_expected.to be_able_to(:autocomplete_user_last_name, User) }

    it { is_expected.to be_able_to(:read, EquipmentItem) }

    context 'checkout persons can edit' do
      it do
        mock_app_config(checkout_persons_can_edit: true)
        ability = Ability.new(user)
        expect(ability).to be_able_to(:update, Reservation)
      end
    end
    context 'checkout persons cannot edit' do
      it do
        mock_app_config(checkout_persons_can_edit: false)
        ability = Ability.new(user)
        expect(ability).not_to be_able_to(:update, Reservation)
      end
    end
    context 'new users enabled' do
      it do
        mock_app_config(enable_new_users: true)
        ability = Ability.new(user)
        expect(ability).to be_able_to(:create, User)
        expect(ability).to be_able_to(:quick_new, User)
        expect(ability).to be_able_to(:quick_create, User)
      end
    end
    context 'new users disabled' do
      it do
        mock_app_config(enable_new_users: true)
        ability = Ability.new(user)
        expect(ability).not_to be_able_to(:create, User)
        expect(ability).not_to be_able_to(:quick_new, User)
        expect(ability).not_to be_able_to(:quick_create, User)
      end
    end
  end

  context 'normal user' do
    let!(:user) { UserMock.new(:user) }
    subject(:ability) { Ability.new(user) }
    it_behaves_like 'all users'
    it_behaves_like 'normal user'
  end

  context 'guest' do
    before { mock_app_config(enable_guests: true) }
    subject(:ability) { Ability.new(UserMock.new(:guest)) }
    it_behaves_like 'all users'

    it { is_expected.to be_able_to(:read, EquipmentModel) }
    it { is_expected.to be_able_to(:empty_cart, :all) }
    it { is_expected.to be_able_to(:reload_catalog_cart, :all) }
    it { is_expected.to be_able_to(:update_cart, :all) }

    context 'new users enabled' do
      it do
        mock_app_config(enable_new_users: true)
        ability = Ability.new(UserMock.new(:guest))
        expect(ability).to be_able_to(:create, User)
      end
    end
    context 'new users disabled' do
      it do
        mock_app_config(enable_new_users: true)
        ability = Ability.new(UserMock.new(:guest))
        expect(ability).to be_able_to(:create, User)
      end
    end
  end

  context 'banned' do
    subject(:ability) { Ability.new(UserMock.new(:banned)) }
    it_behaves_like 'all users'
  end

  context 'renewals disabled' do
    shared_examples 'cannot renew' do |role|
      it do
        mock_app_config(enable_renewals: false)
        ability = Ability.new(UserMock.new(role))
        expect(ability).not_to be_able_to(:renew, Reservation)
      end
    end
    [:admin, :checkout_person, :user].each do |role|
      it_behaves_like 'cannot renew', role
    end
  end
end
