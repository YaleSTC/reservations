FactoryGirl.define do
  factory :checkin_procedure do
    equipment_model_id { FactoryGirl.create(:equipment_model).id }
    step "This is a step of the check-in procedure."
    created_at { Date.yesterday }
    updated_at { Date.today }

    trait :deleted do
      deleted_at { Date.today }
    end
  end
end