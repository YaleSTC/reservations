# frozen_string_literal: true
FactoryGirl.define do
  factory :checkout_procedure do
    equipment_model_id { FactoryGirl.create(:equipment_model).id }
    step 'This is a step of the check-out procedure.'
    created_at { Time.zone.today - 1.day }
    updated_at { Time.zone.today }

    trait :deleted do
      deleted_at { Time.zone.today }
    end
  end
end
