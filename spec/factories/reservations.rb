# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :reservation do
    start_date { Date.today }
    due_date { Date.tomorrow }
    reserver
    equipment_model
    after(:build) do |res|
      obj = FactoryGirl.create(:equipment_object, :equipment_model => res.equipment_model)
      res.equipment_object = obj
    end

    factory :checked_out_reservation do
      checked_out { Date.today }
      association :checkout_handler, factory: :user
    end

    factory :checked_in_reservation do
      start_date { Date.yesterday }
      due_date { Date.today }
      checked_out { Date.yesterday }
      checked_in { Date.today }
      :checkout_handler
      :checkin_handler
    end

    factory :overdue_reservation do
      start_date { Date.yesterday - 1 }
      due_date { Date.yesterday }
      checked_out { Date.yesterday - 1 }
      :checkout_handler
    end
  end
end
