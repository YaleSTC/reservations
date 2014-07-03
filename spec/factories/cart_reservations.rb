# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :cart_reservation do
    start_date { Date.today }
    due_date { Date.tomorrow }
    reserver
    equipment_model

    trait :invalid do
      equipment_model { FactoryGirl.create(:restricted_equipment_model) }
    end

    factory :invalid_cart_reservation, traits: [:invalid]

    factory :valid_cart_reservation do
      after(:build) do |cart_res|
        if cart_res.equipment_model.equipment_objects.empty?
          FactoryGirl.create(:equipment_object, equipment_model: cart_res.equipment_model)
        end
      end
    end
  end
end