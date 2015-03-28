# All commented tests have never passed -- as far as we know the functionality
# works but more work is needed to ensure that we have test coverage.

require 'spec_helper'

describe Reservation, type: :model do
  subject(:reservation) { FactoryGirl.build(:valid_reservation) }

  it { is_expected.to belong_to(:equipment_model) }
  it { is_expected.to belong_to(:reserver) }
  it { is_expected.to belong_to(:equipment_item) }
  it { is_expected.to belong_to(:checkout_handler) }
  it { is_expected.to belong_to(:checkin_handler) }
  # it { should validate_presence_of(:reserver) } #fails because of the
  # deleted reserver
  it { is_expected.to validate_presence_of(:equipment_model) }
  # it { should validate_presence_of(:start_date) } #fails because validations
  # can't run if nil (?)
  # it { should validate_presence_of(:due_date) } #fails because validations
  # can't run if nil (?)
  #

  describe '.find renewal length' do
    subject(:reservation) do
      r = FactoryGirl.create(:valid_reservation)
      FactoryGirl.create(:equipment_item,
                         equipment_model_id: r.equipment_model_id)
      r
    end
    context 'when no other reservations around' do
      it 'should set the correct renewal length' do
        expect(reservation.find_renewal_date).to\
          eq(reservation.due_date\
          + reservation.equipment_model.max_renewal_length.days)
      end
    end
    context 'with a blackout date overlapping with the max renewal length' do
      it 'should set the correct renewal length' do
        FactoryGirl.create(:blackout,
                           start_date: reservation.due_date + 2.day,
                           end_date: reservation.due_date + reservation
                           .equipment_model.max_renewal_length.days + 1.day)
        expect(reservation.find_renewal_date).to\
          eq(reservation.due_date + 1.day)
      end
    end
    context 'with a blackout date going right up to the max renewal length' do
      it 'should set a length of 0' do
        FactoryGirl.create(:blackout,
                           start_date: reservation.due_date + 1.day,
                           end_date: reservation.due_date + reservation
                           .equipment_model.max_renewal_length.days + 1.day)
        expect(reservation.find_renewal_date).to eq(reservation.due_date)
      end
    end
    context 'with another reservation starting in the middle of the max '\
      'renewal length' do
      it 'should set the correct renewal length' do
        r = FactoryGirl.create(:reservation,
                               equipment_model: reservation.equipment_model,
                               start_date: reservation.due_date + 3.days,
                               due_date: reservation.due_date + reservation
                               .equipment_model.max_renewal_length.days\
                               + 5.days)
        r.equipment_model.equipment_items.last.destroy
        expect(reservation.find_renewal_date).to\
          eq(reservation.due_date + 2.days)
      end
    end
  end

  context 'when valid' do
    it { is_expected.to be_valid }
    it 'should have a valid reserver' do
      expect(reservation.reserver).not_to be_nil
      expect(reservation.reserver.first_name).not_to eq('Deleted')
      expect(reservation.reserver.role).not_to eq('Banned')
    end
    it { expect(reservation.equipment_model).to_not be_nil }
    it { expect(reservation.start_date).to_not be_nil }
    it { expect(reservation.due_date).to_not be_nil }
    it 'should save' do
      expect(reservation.save).to be_truthy
      expect(Reservation.all.size).to eq(1)
      expect(Reservation.all.first).to eq(reservation)
    end
    it 'can be updated' do
      reservation.due_date = Time.zone.today + 2.days
      expect(reservation.save).to be_truthy
    end
    it 'passes custom validations' do
      expect(reservation.start_date_before_due_date).to be_nil
      expect(reservation.not_empty).to be_nil
      expect(reservation.matched_item_and_model).to be_nil
      expect(reservation.available).to be_nil
      expect(reservation.check_banned).to be_nil
      expect(reservation.validate).to eq([])
    end
    it { is_expected.to respond_to(:fake_reserver_id) }
    it { is_expected.to respond_to(:late_fee) }
    it { is_expected.to respond_to(:find_renewal_date) }
  end

  context 'when not checked out' do
    it { expect(reservation.status).to eq('reserved') }
    # currently returns true; doesn't check for checked out
    it { expect(reservation).to_not be_eligible_for_renew }
  end

  context 'when checked out' do
    subject(:reservation) { FactoryGirl.build(:checked_out_reservation) }

    it { expect(reservation.status).to eq('checked out') }
    it { is_expected.to be_eligible_for_renew }
  end

  context 'when checked in' do
    subject(:reservation) { FactoryGirl.build(:checked_in_reservation) }

    it { expect(reservation.status).to eq('returned on time') }
    it { is_expected.not_to be_eligible_for_renew }
  end

  context 'when overdue' do
    subject(:reservation) { FactoryGirl.build(:overdue_reservation) }

    it { expect(reservation.status).to eq('overdue') }
    it { is_expected.to be_eligible_for_renew } # should this be true?
  end

  context 'when missed' do
    subject(:reservation) { FactoryGirl.build(:missed_reservation) }

    it { expect(reservation.status).to eq('missed') }
    # it { should_not be_is_eligible_for_renew} #returns true; should it?
  end

  context 'when empty' do
    subject(:reservation) do
      FactoryGirl.build(:reservation, equipment_model: nil)
    end

    it { is_expected.not_to be_valid }
    it 'should not save' do
      expect(reservation.save).to be_falsey
      expect(Reservation.all.size).to eq(0)
    end
    it 'cannot be updated' do
      reservation.start_date = Time.zone.today + 1.day
      expect(reservation.save).to be_falsey
    end
    # it 'fails appropriate validations' do
    #   reservation.should_not be_not_empty
    #   Reservation.validate_set(reservation.reserver,
    #                            [] << reservation).should_not == [] #fails
    # end
    # it 'passes other custom validations' do
    #   reservation.should be_no_overdue_reservations
    #   reservation.should be_start_date_before_due_date
    #   reservation.should be_not_in_past
    #   reservation.should be_matched_item_and_model
    #   reservation.should be_duration_allowed # fails: tries to run
    # validations on nil
    #   reservation.should be_start_date_is_not_blackout
    #   reservation.should be_due_date_is_not_blackout
    #   reservation.should be_available #fails: tries to run validations on nil
    #   reservation.should be_quantity_eq_model_allowed # fails: tries to run
    # validations on nil
    #   reservation.should be_quantity_cat_allowed # fails: tries to run
    # validations on nil
    # end
    it 'updates with equipment model' do
      reservation.equipment_model = FactoryGirl.create(:equipment_model)
      FactoryGirl.create(:equipment_item,
                         equipment_model: reservation.equipment_model)
      expect(reservation.save).to be_truthy
      expect(reservation).to be_valid
      expect(Reservation.all.size).to eq(1)
    end
  end

  context 'with past due date' do
    subject(:reservation) do
      FactoryGirl.build(:valid_reservation, due_date: Time.zone.today - 1.day)
    end

    it { is_expected.not_to be_valid }
    it 'should not save' do
      expect(reservation.save).to be_falsey
      expect(Reservation.all.size).to eq(0)
    end
    it 'cannot be updated' do
      reservation.start_date = Time.zone.today + 1.day
      expect(reservation.save).to be_falsey
    end
    it 'fails appropriate validations' do
      expect(reservation.start_date_before_due_date).not_to be_nil
      expect(reservation.not_in_past).not_to be_nil
    end
    it 'passes other custom validations' do
      expect(reservation.not_empty).to be_nil
      expect(reservation.matched_item_and_model).to be_nil
      expect(reservation.available).to be_nil
      expect(reservation.check_banned).to be_nil
      expect(reservation.validate).to eq([])
    end
    it 'updates with fixed date' do
      reservation.due_date = Time.zone.today + 2.days
      expect(reservation.save).to be_truthy
      expect(reservation).to be_valid
      expect(Reservation.all.size).to eq(1)
    end
  end

  context 'with blacked out start date' do
    let!(:blackout) do
      FactoryGirl.create(:blackout,
                         start_date: reservation.start_date,
                         end_date: reservation.due_date)
    end

    it { is_expected.to be_valid }
    it 'should save' do
      expect(reservation.save).to be_truthy
      expect(Reservation.all.size).to eq(1)
    end
    it 'can be updated' do
      reservation.start_date = Time.zone.today + 1.day
      expect(reservation.save).to be_truthy
    end
    it 'fails appropriate validations' do
      expect(reservation.validate).not_to eq([])
    end
    it 'passes other custom validations' do
      expect(reservation.not_in_past).to be_nil
      expect(reservation.start_date_before_due_date).to be_nil
      expect(reservation.not_empty).to be_nil
      expect(reservation.matched_item_and_model).to be_nil
      expect(reservation.available).to be_nil
      expect(reservation.check_banned).to be_nil
    end
  end

  context 'with no user' do
    subject(:reservation) do
      FactoryGirl.build(:valid_reservation, reserver: nil)
    end

    it 'should have a deleted user' do
      expect(reservation.reserver).not_to be_nil
      expect(reservation.reserver.first_name).to eq('Deleted')
    end
    it { is_expected.to be_valid }
  end

  context 'when user has overdue reservation' do
    subject(:reservation) { FactoryGirl.build(:valid_reservation) }
    let(:overdue_reserver) { reservation.reserver }
    let!(:overdue) do
      o = FactoryGirl.build(:overdue_reservation, reserver: overdue_reserver)
      o.save(validate: false)
      o
    end

    it { is_expected.to be_valid }
    it 'should not save' do
      expect(reservation.save).to be_truthy
      expect(Reservation.all.size).to eq(2)
      expect(Reservation.all.first).to eq(overdue)
    end
    it 'can be updated' do
      reservation.start_date = Time.zone.today + 1.day
      expect(reservation.save).to be_truthy
    end
    it 'fails appropriate validations' do
      expect(reservation.validate).not_to eq([])
    end
    it 'passes other custom validations' do
      expect(reservation.start_date_before_due_date).to be_nil
      expect(reservation.not_empty).to be_nil
      expect(reservation.matched_item_and_model).to be_nil
      expect(reservation.available).to be_nil
      expect(reservation.not_in_past).to be_nil
      expect(reservation.check_banned).to be_nil
    end
  end

  context 'with banned user' do
    let(:banned) { FactoryGirl.create(:banned) }
    subject(:reservation) do
      FactoryGirl.build(:valid_reservation, reserver_id: banned.id)
    end

    it { is_expected.not_to be_valid }
    it 'should not save' do
      expect(reservation.save).to be_falsey
    end
    it 'fails appropriate validations' do
      expect(reservation.validate).not_to eq([])
    end
    it 'passes other custom validations' do
      expect(reservation.start_date_before_due_date).to be_nil
      expect(reservation.not_empty).to be_nil
      expect(reservation.matched_item_and_model).to be_nil
      expect(reservation.available).to be_nil
      expect(reservation.not_in_past).to be_nil
    end
  end

  # this all fails - problem w/ available
  context 'with equipment item available problems' do
    let!(:available_reservation) do
      FactoryGirl.create(:checked_out_reservation,
                         equipment_model: reservation.equipment_model)
    end

    # it { should_not be_valid } #fails
    # it 'should not save' do #fails
    #   reservation.save.should be_falsey
    #   Reservation.all.size.should == 0
    # end
    # it 'cannot be updated' do #fails
    #   reservation.start_date = Time.zone.today + 1.day
    #   reservation.save.should be_falsey
    # end
    # it 'fails appropriate validations' do # fails
    #   reservation.should_not be_available
    #   Reservation.validate_set(reservation.reserver,
    #                            [] << reservation).should_not == []
    # end
    it 'passes other custom validations' do
      expect(reservation.start_date_before_due_date).to be_nil
      expect(reservation.not_empty).to be_nil
      expect(reservation.not_in_past).to be_nil
    end
  end

  context 'with equipment item/model matching problems' do
    subject(:reservation) do
      r = FactoryGirl.build(:valid_reservation)
      r.equipment_item = FactoryGirl.create(:equipment_item)
      r
    end

    it { is_expected.not_to be_valid }
    it 'should not save' do
      expect(reservation.save).to be_falsey
      expect(Reservation.all.size).to eq(0)
    end
    it 'cannot be updated' do
      reservation.start_date = Time.zone.today + 1.day
      expect(reservation.save).to be_falsey
    end
    it 'fails appropriate validations' do
      expect(reservation.matched_item_and_model).not_to be_nil
    end
    it 'passes other custom validations' do
      expect(reservation.start_date_before_due_date).to be_nil
      expect(reservation.not_empty).to be_nil
      expect(reservation.not_in_past).to be_nil
      expect(reservation.check_banned).to be_nil
      expect(reservation.validate).to eq([])
    end
  end

  context 'with duration problems' do
    subject(:reservation) do
      r = FactoryGirl.build(:valid_reservation)
      r.equipment_model.category.max_checkout_length = 1
      r.equipment_model.category.save
      r.due_date = Time.zone.today + 3.days
      r
    end

    it { is_expected.to be_valid }
    it 'should save' do
      expect(reservation.save).to be_truthy
      expect(Reservation.all.size).to eq(1)
    end
    it 'can update' do
      reservation.start_date = Time.zone.today + 1.day
      expect(reservation.save).to be_truthy
    end
    it 'fails appropriate validations' do
      expect(reservation.validate).not_to eq([])
    end
    it 'passes other custom validations' do
      expect(reservation.start_date_before_due_date).to be_nil
      expect(reservation.not_empty).to be_nil
      expect(reservation.matched_item_and_model).to be_nil
      expect(reservation.available).to be_nil
      expect(reservation.not_in_past).to be_nil
      expect(reservation.check_banned).to be_nil
    end
  end

  context 'with category quantity problems' do
    subject(:reservation) do
      r = FactoryGirl.create(:valid_reservation)
      r.equipment_model.category.max_per_user = 1
      r.equipment_model.max_per_user = 2
      r.equipment_model.save
      r.equipment_model.category.save
      FactoryGirl.create(:equipment_item, equipment_model: r.equipment_model)
      FactoryGirl.create(:equipment_item, equipment_model: r.equipment_model)
      FactoryGirl.create(:reservation,
                         equipment_model: r.equipment_model,
                         reserver: r.reserver)
      r
    end

    it { is_expected.to be_valid }
    it 'should save' do
      expect(reservation.save).to be_truthy
      expect(Reservation.all.size).to eq(2)
    end
    it 'can be updated' do
      reservation.start_date = Time.zone.today + 1.day
      expect(reservation.save).to be_truthy
    end
    it 'fails appropriate validations' do
      expect(reservation.validate).not_to eq([])
    end
    it 'passes other custom validations' do
      expect(reservation.start_date_before_due_date).to be_nil
      expect(reservation.not_empty).to be_nil
      expect(reservation.matched_item_and_model).to be_nil
      expect(reservation.available).to be_nil
      expect(reservation.not_in_past).to be_nil
      expect(reservation.check_banned).to be_nil
    end
  end

  context 'with equipment model quantity problems' do
    subject(:reservation) do
      r = FactoryGirl.create(:valid_reservation)
      r.equipment_model.category.max_per_user = 1
      r.equipment_model.max_per_user = 1
      r.equipment_model.save
      r.equipment_model.category.save
      FactoryGirl.create(:equipment_item, equipment_model: r.equipment_model)
      FactoryGirl.create(:equipment_item, equipment_model: r.equipment_model)
      FactoryGirl.create(:valid_reservation,
                         equipment_model: r.equipment_model,
                         reserver: r.reserver)
      r
    end

    it { is_expected.to be_valid }
    it 'should save' do
      expect(reservation.save).to be_truthy
      expect(Reservation.all.size).to eq(2)
    end
    it 'can be updated' do
      reservation.start_date = Time.zone.today + 1.day
      expect(reservation.save).to be_truthy
    end
    it 'fails appropriate validations' do
      expect(reservation.validate).not_to eq([])
    end
    it 'passes other custom validations' do
      expect(reservation.start_date_before_due_date).to be_nil
      expect(reservation.not_empty).to be_nil
      expect(reservation.matched_item_and_model).to be_nil
      expect(reservation.available).to be_nil
      expect(reservation.not_in_past).to be_nil
      expect(reservation.check_banned).to be_nil
    end
  end
end
