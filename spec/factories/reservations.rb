# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :reservation do
    start_date { Date.today }
    due_date { Date.tomorrow }
    reserver
    equipment_model

    factory :valid_reservation do
      after(:build) do |res|
        #for some reason this code is required instead of just calling it on res.equipment_model
        mod = EquipmentModel.find(res.equipment_model)
        if mod.equipment_objects.empty?
          FactoryGirl.create(:equipment_object, equipment_model: mod)
        end
      end

      factory :checked_out_reservation do
        checked_out { Date.today }
        checkout_handler
        after(:build) do |res|
          mod = EquipmentModel.find(res.equipment_model)
          res.equipment_object = mod.equipment_objects.first
        end

        factory :checked_in_reservation do
          start_date { Date.yesterday }
          due_date { Date.today }
          checked_out { Date.yesterday }
          checked_in { Date.today }
          checkin_handler
        end

        factory :overdue_reservation do
          start_date { Date.yesterday - 1 }
          due_date { Date.yesterday }
          checked_out { Date.yesterday - 1 }
        end
      end

      factory :missed_reservation do
        start_date { Date.yesterday - 1 }
        due_date { Date.yesterday }
      end
    end
  end
end
