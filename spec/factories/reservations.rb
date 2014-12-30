# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :reservation do
    start_date { Date.current }
    due_date { Date.tomorrow }
    reserver
    equipment_model

    trait :valid do
      after(:build) do |res|
        # for some reason this code is required instead of just calling it on res.equipment_model
        mod = EquipmentModel.find(res.equipment_model)
        if mod.equipment_objects.empty?
          FactoryGirl.create(:equipment_object, equipment_model: mod)
        end
      end
    end

    trait :reserved do
      start_date { Date.current }
      due_date { Date.tomorrow }
    end

    trait :checked_out do
      checked_out { Date.current }
      checkout_handler
      after(:build) do |res|
        mod = EquipmentModel.find(res.equipment_model)
        res.equipment_object = mod.equipment_objects.first
      end
    end

    trait :missed do
      start_date { Date.yesterday - 1 }
      due_date { Date.yesterday }
      to_create do |instance|
        instance.save(validate: false)
      end
    end

    trait :returned do
      start_date { Date.yesterday }
      due_date { Date.current }
      checked_out { Date.yesterday }
      checked_in { Date.current }
      checkin_handler
    end

    trait :upcoming do
      start_date { Date.current }
    end

    trait :overdue do
      start_date { Date.yesterday - 1 }
      due_date { Date.yesterday }
      checked_out { Date.yesterday - 1 }
      after(:build) do |res|
        mod = EquipmentModel.find(res.equipment_model)
        res.equipment_object = mod.equipment_objects.first
      end
    end

    factory :valid_reservation, traits: [:valid]
    factory :checked_out_reservation, traits: [:valid, :checked_out]
    factory :checked_in_reservation, traits: [:valid, :checked_out, :returned]
    factory :overdue_reservation, traits: [:valid, :overdue]
    factory :missed_reservation, traits: [:valid, :missed]
  end
end
