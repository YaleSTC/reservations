# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :reservation do
    start_date { Time.zone.today }
    due_date { Time.zone.today + 1.day }
    reserver
    equipment_model
    status { 'reserved' }

    trait :valid do
      after(:build) do |res|
        # for some reason this code is required instead of just calling it on
        # res.equipment_model
        mod = EquipmentModel.find(res.equipment_model)
        if mod.equipment_items.empty?
          FactoryGirl.create(:equipment_item, equipment_model: mod)
        end
      end
    end

    trait :request do
      start_date { Time.zone.today }
      due_date { Time.zone.today + 1.day }
      status { 'requested' }
      after(:build) do |res|
        res.flag(:request)
      end
    end

    trait :reserved do
      start_date { Time.zone.today }
      due_date { Time.zone.today + 1.day }
      status { 'reserved' }
    end

    trait :checked_out do
      checked_out { Time.zone.today }
      status { 'checked_out' }
      checkout_handler
      after(:build) do |res|
        mod = EquipmentModel.find(res.equipment_model)
        res.equipment_item = mod.equipment_items.first
      end
    end

    trait :missed do
      start_date { Time.zone.yesterday }
      due_date { Time.zone.today }
      status { 'missed' }
      to_create do |instance|
        instance.save(validate: false)
      end
    end

    trait :returned do
      start_date { Time.zone.today - 1.days }
      due_date { Time.zone.today }
      checked_out { Time.zone.today - 1.days }
      checked_in { Time.zone.today }
      status { 'returned' }
      checkin_handler
    end

    trait :upcoming do
      start_date { Time.zone.today }
    end

    trait :overdue do
      start_date { Time.zone.today - 2.days }
      due_date { Time.zone.today - 1.days }
      checked_out { Time.zone.today - 2.days }
      overdue { true }
      after(:build) do |res|
        mod = EquipmentModel.find(res.equipment_model)
        res.equipment_item = mod.equipment_items.first
      end
    end

    factory :valid_reservation, traits: [:valid]
    factory :checked_out_reservation, traits: [:valid, :checked_out]
    factory :checked_in_reservation, traits: [:valid, :checked_out, :returned]
    factory :overdue_reservation, traits: [:valid, :checked_out, :overdue]
    factory :overdue_returned_reservation, traits: [:valid, :checked_out,
                                                    :returned, :overdue]
    factory :upcoming_reservation, traits: [:valid, :upcoming]
    factory :missed_reservation, traits: [:valid, :missed]
    factory :request, traits: [:valid, :request]
  end
end
