# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  sequence(:unique_id) { |n| n }

  factory :equipment_model do
    name
    description "This is a model"
    late_fee "37.50"
    replacement_fee "20"
    max_per_user 10
    category
    max_renewal_times 10
    max_renewal_length 10
    renewal_days_before_due 10
    
    factory :equipment_model_with_object do
      after(:create) do |model|
        FactoryGirl.create(:equipment_object, equipment_model: model)
      end
    end
  end
end