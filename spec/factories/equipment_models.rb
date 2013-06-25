# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  sequence(:unique_id) { |n| n }

  factory :equipment_model do
    id { generate(:unique_id) }
    name
    description "This is a model"
    late_fee "37.50"
    replacement_fee "20"
    max_per_user 10
    category factory: :category
    max_renewal_times 10
    max_renewal_length 10
    renewal_days_before_due 10
  end
end
