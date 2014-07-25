FactoryGirl.define do
  factory :checkout_procedure do
    equipment_model_id { FactoryGirl.create(:equipment_model).id }
    step "This is a step of the check-out procedure."
    created_at { Date.yesterday }
    updated_at { Date.current }

    trait :deleted do
      deleted_at { Date.current }
    end
  end
end